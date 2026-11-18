"""Paired comparisons between conditions, with intervals.

The unit is the task: each condition is first averaged over its repeats per
task, and two conditions are compared task by task on the tasks both have.
Every interval comes from one method, a seeded bootstrap that resamples whole
groups (for ChipBench, modules), so tasks that share a module stay together.
"""

from __future__ import annotations

import math
import random
from collections import defaultdict
from statistics import mean, pstdev

from .metrics import Row, by_task, cost, task_rate, total_tokens

RESAMPLES = 2000
SEED = 1


def bootstrap(per_task: dict[str, float], group_of: dict[str, str], statistic=mean,
              resamples: int = RESAMPLES, seed: int = SEED) -> dict:
    """A value with a 95% interval, resampling groups with replacement."""
    if not per_task:
        return {"value": None, "low": None, "high": None, "se": None, "tasks": 0}
    groups: dict[str, list[float]] = defaultdict(list)
    for task, value in per_task.items():
        groups[group_of[task]].append(value)
    names = sorted(groups)
    rng = random.Random(seed)
    draws = []
    for _ in range(resamples):
        sample = [v for name in rng.choices(names, k=len(names)) for v in groups[name]]
        draws.append(statistic(sample))
    draws.sort()
    return {"value": statistic(list(per_task.values())),
            "low": draws[int(0.025 * resamples)], "high": draws[int(0.975 * resamples) - 1],
            "se": pstdev(draws), "tasks": len(per_task)}


def geometric_mean(values: list[float]) -> float:
    return math.exp(mean(math.log(v) for v in values if v > 0)) if any(v > 0 for v in values) else 0.0


def rate(rows: list[Row]) -> dict:
    """A condition's pass rate with its interval."""
    tasks = by_task(rows)
    group_of = {t: v[0].group for t, v in tasks.items()}
    return bootstrap({t: task_rate(v) for t, v in tasks.items()}, group_of)


def paired(kb_rows: list[Row], reference_rows: list[Row], prices: dict, model: str) -> dict:
    """One condition against another, task by task."""
    kb_tasks, ref_tasks = by_task(kb_rows), by_task(reference_rows)
    shared = sorted(set(kb_tasks) & set(ref_tasks))
    if not shared:
        return {"tasks": 0}
    group_of = {t: kb_tasks[t][0].group for t in shared}
    difference = {t: task_rate(kb_tasks[t]) - task_rate(ref_tasks[t]) for t in shared}

    def ratio(value) -> dict[str, float]:
        out = {}
        for t in shared:
            ours = mean(value(r) for r in kb_tasks[t])
            theirs = mean(value(r) for r in ref_tasks[t])
            if ours > 0 and theirs > 0:
                out[t] = ours / theirs
        return out

    def seconds(row: Row) -> float:
        return row.seconds or 0.0

    pass_difference = bootstrap(difference, group_of)
    return {
        "tasks": len(shared),
        "pass_rate_difference": pass_difference,
        "helped": sum(1 for d in difference.values() if d > 0),
        "harmed": sum(1 for d in difference.values() if d < 0),
        "unchanged": sum(1 for d in difference.values() if d == 0),
        "token_ratio": bootstrap(ratio(lambda r: total_tokens(r.usage)), group_of, geometric_mean),
        "cost_ratio": bootstrap(ratio(lambda r: cost(r.usage, prices, model)), group_of, geometric_mean),
        "time_ratio": bootstrap(ratio(seconds), group_of, geometric_mean),
        # With 80% power at the 5% level, the smallest true difference this
        # comparison could tell from chance.
        "smallest_detectable_difference": (2.8 * pass_difference["se"]
                                           if pass_difference["se"] is not None else None),
    }


def repeat_noise(rows: list[Row]) -> dict:
    """How far apart two repeats of the same condition land: what chance alone does."""
    first = [r for r in rows if r.repeat == 0]
    second = [r for r in rows if r.repeat == 1]
    a, b = by_task(first), by_task(second)
    shared = sorted(set(a) & set(b))
    if not shared:
        return {"tasks": 0}
    group_of = {t: a[t][0].group for t in shared}
    difference = bootstrap({t: task_rate(a[t]) - task_rate(b[t]) for t in shared}, group_of)
    return {"tasks": len(shared), "difference": difference,
            "smallest_detectable_difference": 2.8 * difference["se"]}


def build_cost(build_rows: list[Row], baseline_a_rows: list[Row], prices: dict, model: str) -> dict:
    """What building a KB cost: a chain's tokens, dollars and time over the
    baseline's on the same tasks. A one-time cost, apart from per-run cost."""
    baseline = by_task(baseline_a_rows)
    chains: dict[int, list[Row]] = defaultdict(list)
    for row in build_rows:
        chains[row.repeat].append(row)
    extras = []
    for rows in chains.values():
        tokens = dollars = seconds = 0.0
        for row in rows:
            reference = baseline.get(row.task_id, [])
            tokens += total_tokens(row.usage) + total_tokens(row.update_usage)
            dollars += cost(row.usage, prices, model) + cost(row.update_usage, prices, model)
            seconds += (row.seconds or 0) + (row.update_seconds or 0)
            if reference:
                tokens -= mean(total_tokens(r.usage) for r in reference)
                dollars -= mean(cost(r.usage, prices, model) for r in reference)
                seconds -= mean(r.seconds or 0 for r in reference)
        extras.append({"tokens": tokens, "dollars": dollars, "seconds": seconds, "runs": len(rows)})
    if not extras:
        return {}
    return {"chains": len(extras), "tokens": mean(e["tokens"] for e in extras),
            "dollars": mean(e["dollars"] for e in extras), "seconds": mean(e["seconds"] for e in extras),
            "contribution_rate": mean(1.0 if r.kb_changed else 0.0 for r in build_rows)}


def break_even(build: dict, eval_rows: list[Row], baseline_b_rows: list[Row], prices: dict,
               model: str) -> dict:
    """The number of tasks after which the KB has paid for itself, if it ever does."""
    kb_tasks, ref_tasks = by_task(eval_rows), by_task(baseline_b_rows)
    shared = sorted(set(kb_tasks) & set(ref_tasks))
    if not shared or not build:
        return {}
    saving = mean(mean(cost(r.usage, prices, model) for r in ref_tasks[t])
                  - mean(cost(r.usage, prices, model) for r in kb_tasks[t]) for t in shared)
    return {"saving_per_task_dollars": saving,
            "tasks_to_break_even": (build["dollars"] / saving) if saving > 0 else None}


def limitations(kb_rows: list[Row], reference_rows: list[Row]) -> dict:
    """Per category: how much of the baseline's rate went, stayed, or was added."""
    kb_tasks = by_task([r for r in kb_rows if r.limitations is not None])
    ref_tasks = by_task([r for r in reference_rows if r.limitations is not None])
    shared = sorted(set(kb_tasks) & set(ref_tasks))
    if not shared:
        return {}
    categories = sorted({c for t in shared for r in [*kb_tasks[t], *ref_tasks[t]] for c in r.limitations})
    out = {}
    for category in categories:
        resolved, persisting, introduced = [], [], []
        for t in shared:
            before = mean(1.0 if category in r.limitations else 0.0 for r in ref_tasks[t])
            after = mean(1.0 if category in r.limitations else 0.0 for r in kb_tasks[t])
            resolved.append(max(before - after, 0.0))
            persisting.append(min(before, after))
            introduced.append(max(after - before, 0.0))
        out[category] = {"resolved": mean(resolved), "persisting": mean(persisting),
                         "introduced": mean(introduced)}
    return out


def limitation_rates(rows: list[Row]) -> dict:
    assessed = [r for r in rows if r.limitations is not None]
    if not assessed:
        return {}
    categories = sorted({c for r in assessed for c in r.limitations})
    return {c: mean(1.0 if c in r.limitations else 0.0 for r in assessed) for c in categories}
