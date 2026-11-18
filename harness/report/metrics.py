"""Per-run and per-condition metrics, computed from stored runs."""

from __future__ import annotations

import json
import tomllib
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path
from statistics import mean, median

from harness.dataset.loader import load_dataset, load_split
from harness.records import store

TOKEN_PARTS = ("input_uncached", "input_cached", "output")


@dataclass
class Row:
    """One run, reduced to what the report needs."""

    experiment: str
    condition: str
    mode: str
    kb: str | None
    side: str
    task_id: str
    group: str
    tags: dict
    repeat: int
    position: int | None
    status: str
    passed: bool
    pending: bool
    usage: dict
    seconds: float | None
    update_usage: dict
    update_seconds: float | None
    tools: Counter
    kb_changed: bool
    kb_used: bool | None
    limitations: frozenset | None
    monitor_status: str | None
    findings: list
    review: str | None

    @property
    def label(self) -> str:
        return self.condition if self.experiment == self.condition else f"{self.experiment}/{self.condition}"


@dataclass
class Loaded:
    rows: list[Row]
    experiments: dict[str, dict]            # name -> experiment.json
    provisional: bool
    pending: int
    planned: dict[tuple[str, str], int]     # (experiment, condition) -> planned runs
    redteam: list[Row] = field(default_factory=list)


def load_prices(path: Path) -> dict:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def cost(usage: dict, prices: dict, model: str) -> float:
    """Dollars for one turn's tokens, from the dated price table."""
    table = prices["models"][model]
    written = usage.get("input_cache_write", 0)
    plain = max(usage.get("input_uncached", 0) - written, 0)
    return (plain * table["input"] + written * table.get("cache_write", table["input"])
            + usage.get("input_cached", 0) * table["cached_input"]
            + usage.get("output", 0) * table["output"]) / 1_000_000


def _kb_markers(setup: dict) -> list[str]:
    """Strings that show a step touched the KB: its paths, its links, its search tool."""
    kb = setup.get("kb") or {}
    if not kb:
        return []
    markers = [kb.get("path", "/kb"), "kbsearch", *(kb.get("paths") or {}).values()]
    markers += [target for target in (kb.get("links") or {}) if not target.endswith("AGENTS.md")]
    return [m for m in markers if m]


def _tools_and_kb_use(run: store.Run, markers: list[str]) -> tuple[Counter, bool | None]:
    trajectory = run.trajectory("solve") or {}
    steps = trajectory.get("steps", [])
    last_user = max((i for i, s in enumerate(steps) if s.get("source") == "user"), default=-1)
    tools: Counter = Counter()
    used = False
    for step in steps[last_user + 1:]:
        for call in step.get("tool_calls") or []:
            tools[call.get("function_name", "tool")] += 1
            if markers and any(m in json.dumps(call.get("arguments", "")) for m in markers):
                used = True
    return tools, (used if markers else None)


def load(experiment_dirs: list[Path], root: Path) -> Loaded:
    """Every run of the given experiments, as rows. Results are by Verdict alone
    while anything is pending, and the report is then provisional."""
    rows, redteam, experiments, planned = [], [], {}, {}
    runs_by_experiment = {}
    for directory in experiment_dirs:
        info = store.load_experiment_info(directory)
        experiments[info["name"]] = info
        runs_by_experiment[info["name"]] = (directory, info, store.load_runs(directory))

    pending = sum(1 for _, info, runs in runs_by_experiment.values() if info.get("kind") != "redteam"
                  for run in runs if run.result == "pending")
    for name, (directory, info, runs) in runs_by_experiment.items():
        dataset = load_dataset(root / "datasets" / info["dataset"])
        split = load_split(dataset, info["split"])
        side_of = {**{t: "A" for t in split.a}, **{t: "B" for t in split.b}}
        resolved = info["resolved"]
        excluded, only = set(resolved.get("excluded_tasks", [])), resolved.get("tasks")
        for condition in resolved.get("conditions", []):
            tasks = [t for side in condition.get("side", ["B"]) for t in split.side(side)
                     if t not in excluded and (only is None or t in only)]
            planned[(name, condition["name"])] = len(tasks) * int(resolved.get("repeats", 3))
        setups = {h: json.loads((directory / "setups" / f"{h}.json").read_text())
                  for h in set(info.get("setups", {}).values())}
        for run in runs:
            task = dataset.tasks[run.task_id]
            setup = setups.get(run.record["provenance"]["setup_hash"], {})
            continued = (setup.get("agent_memory") or {}).get("session") == "continue"
            tools, kb_used = _tools_and_kb_use(run, _kb_markers(setup))
            outcome = run.result if pending == 0 else run.verdict_result
            assessment = run.assessment
            row = Row(
                experiment=name, condition=run.condition, mode=run.mode,
                kb=run.record["condition"].get("kb"), side=side_of.get(run.task_id, "?"),
                task_id=run.task_id, group=dataset.group_of(run.task_id), tags=task.tags,
                repeat=run.repeat, position=run.record.get("position"), status=run.status,
                passed=outcome == "pass", pending=run.result == "pending",
                usage=run.usage("solve"), seconds=run.seconds("solve"),
                update_usage=run.usage("update"), update_seconds=run.seconds("update"),
                tools=tools, kb_changed=bool(run.record["kb"].get("changed")),
                kb_used=None if continued else kb_used,
                limitations=(frozenset(item["category"] for item in assessment["limitations"])
                             if assessment else None),
                monitor_status=(run.monitor or {}).get("status"),
                findings=(run.monitor or {}).get("findings", []),
                review=(run.review or {}).get("decision"),
            )
            (redteam if info.get("kind") == "redteam" else rows).append(row)
    return Loaded(rows, experiments, pending > 0, pending, planned, redteam)


def by_task(rows: list[Row]) -> dict[str, list[Row]]:
    grouped: dict[str, list[Row]] = defaultdict(list)
    for row in rows:
        grouped[row.task_id].append(row)
    return grouped


def task_rate(rows: list[Row]) -> float:
    return mean(1.0 if r.passed else 0.0 for r in rows)


def total_tokens(usage: dict) -> int:
    return sum(usage.get(part, 0) for part in TOKEN_PARTS)


def condition_metrics(rows: list[Row], prices: dict, model: str) -> dict:
    """Headline and process metrics for one condition on one side."""
    tasks = by_task(rows)
    if not tasks:
        return {}
    costs = [cost(r.usage, prices, model) for r in rows]
    passes = sum(1 for r in rows if r.passed)
    seconds = [r.seconds for r in rows if r.seconds is not None]
    tools: Counter = Counter()
    for row in rows:
        tools.update(row.tools)
    repeats = max(len(v) for v in tasks.values())
    return {
        "tasks": len(tasks), "runs": len(rows), "repeats": repeats,
        "pass_rate": mean(task_rate(v) for v in tasks.values()),
        f"pass@{repeats}": mean(1.0 if any(r.passed for r in v) else 0.0 for v in tasks.values()),
        f"pass^{repeats}": mean(1.0 if all(r.passed for r in v) else 0.0 for v in tasks.values()),
        "tokens_per_run": {part: mean(r.usage.get(part, 0) for r in rows) for part in TOKEN_PARTS},
        "tokens_per_run_total": mean(total_tokens(r.usage) for r in rows),
        "cost_per_run": mean(costs),
        "cost_per_solved_task": (sum(costs) / passes) if passes else None,
        "seconds_mean": mean(seconds) if seconds else None,
        "seconds_median": median(seconds) if seconds else None,
        "responses_per_run": mean(r.usage.get("responses", 0) for r in rows),
        "steps_per_run": {tool: count / len(rows) for tool, count in sorted(tools.items())},
        "kb_use": (mean(1.0 if r.kb_used else 0.0 for r in rows if r.kb_used is not None)
                   if any(r.kb_used is not None for r in rows) else None),
        "outcomes": dict(Counter(r.status for r in rows)),
    }


def within_budget(rows: list[Row], points: int = 12) -> list[dict]:
    """Share of tasks solved within a given number of tokens. A failure never is."""
    tasks = by_task(rows)
    spend = sorted(total_tokens(r.usage) for r in rows)
    if not spend:
        return []
    thresholds = sorted({spend[min(len(spend) - 1, int(i * len(spend) / points))] for i in range(1, points + 1)})
    curve = []
    for limit in thresholds:
        solved = mean(mean(1.0 if r.passed and total_tokens(r.usage) <= limit else 0.0 for r in v)
                      for v in tasks.values())
        curve.append({"tokens": limit, "solved": solved})
    return curve


def learning_curve(build_rows: list[Row]) -> list[dict]:
    """Pass rate and tokens in a build chain, by position in the chain."""
    by_position: dict[int, list[Row]] = defaultdict(list)
    for row in build_rows:
        if row.position is not None:
            by_position[row.position].append(row)
    return [{"position": p, "pass_rate": task_rate(v), "tokens": mean(total_tokens(r.usage) for r in v)}
            for p, v in sorted(by_position.items())]
