"""Builds a report from stored runs: summary.json, report.md, per_task.csv, figures.

A pure function of records and prices. It never runs an agent or a grader,
every planned run stays in the denominator, and while any run is pending the
report is marked provisional and shows results by Verdict alone.
"""

from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path
from statistics import mean

from . import compare
from .metrics import Loaded, Row, by_task, condition_metrics, cost, learning_curve, load, load_prices, \
    task_rate, total_tokens, within_budget


class ReportError(ValueError):
    """Experiments that must not be compared."""


def _check_comparable(loaded: Loaded) -> None:
    """One baseline, shared: refuse experiments that were not run alike."""
    keys = ("base_setup_hash", "dataset_version", "split", "seed")
    seen = {}
    for name, info in loaded.experiments.items():
        if info.get("kind") == "redteam":
            continue
        for key in keys:
            seen.setdefault(key, {})[name] = info.get(key)
    for key, values in seen.items():
        if len(set(values.values())) > 1:
            raise ReportError(f"experiments differ in {key}: {values}")


def _select(rows: list[Row], **want) -> list[Row]:
    return [r for r in rows if all(getattr(r, k) == v for k, v in want.items())]


def _model(root: Path, loaded: Loaded) -> str:
    for name, info in loaded.experiments.items():
        for setup_hash in info.get("setups", {}).values():
            file = root / "runs" / name / "setups" / f"{setup_hash}.json"
            if file.is_file():
                return json.loads(file.read_text())["model"]
    raise ReportError("no stored Setup to read the model from")


def build_report(experiment_dirs: list[Path], prices_path: Path, out_dir: Path) -> dict:
    experiment_dirs = [Path(d) for d in experiment_dirs]
    root = experiment_dirs[0].parents[1]
    loaded = load(experiment_dirs, root)
    _check_comparable(loaded)
    prices = load_prices(prices_path)
    model = _model(root, loaded)
    rows = loaded.rows

    baseline = _select(rows, mode="baseline")
    labels = sorted({(r.experiment, r.condition, r.mode, r.kb) for r in rows})

    conditions = {}
    for experiment, condition, mode, kb in labels:
        chosen = _select(rows, experiment=experiment, condition=condition)
        for side in ("A", "B"):
            on_side = _select(chosen, side=side)
            if not on_side:
                continue
            entry = condition_metrics(on_side, prices, model)
            entry.update(mode=mode, kb=kb, pass_rate_interval=compare.rate(on_side),
                         within_budget=within_budget(on_side),
                         limitation_rates=compare.limitation_rates(on_side),
                         by_category={c: task_rate([r for r in on_side if r.tags.get("category") == c])
                                      for c in sorted({r.tags.get("category", "") for r in on_side})})
            conditions.setdefault(chosen[0].label, {})[side] = entry

    comparisons, kb_metrics = {}, {}
    for experiment in sorted({r.experiment for r in rows if r.mode != "baseline"}):
        mine = _select(rows, experiment=experiment)
        build = [r for r in mine if r.mode == "build"]
        evals = [r for r in mine if r.mode == "eval"]
        built = [r for r in evals if r.condition != "empty"]
        empty = [r for r in evals if r.condition == "empty"]
        on_b = _select(built, side="B")
        entry = {}
        if on_b and baseline:
            entry["vs_baseline"] = compare.paired(on_b, _select(baseline, side="B"), prices, model)
            entry["limitations_vs_baseline"] = compare.limitations(on_b, _select(baseline, side="B"))
        if on_b and empty:
            entry["vs_empty_kb"] = compare.paired(on_b, _select(empty, side="B"), prices, model)
        if empty and baseline:
            entry["empty_kb_vs_baseline"] = compare.paired(_select(empty, side="B"),
                                                           _select(baseline, side="B"), prices, model)
        comparisons[experiment] = entry
        cost_of_building = compare.build_cost(build, _select(baseline, side="A"), prices, model)
        kb_metrics[experiment] = {
            "build_cost": cost_of_building,
            "break_even": compare.break_even(cost_of_building, on_b, _select(baseline, side="B"),
                                             prices, model),
            "learning_curve": learning_curve(build),
        }

    findings = Counter(f.get("category") for r in rows for f in r.findings
                       if f.get("intent") in ("enacted", "attempted"))
    run_counts = {}
    for (experiment, condition), planned in loaded.planned.items():
        mine = _select(rows, experiment=experiment, condition=condition)
        if experiment not in {r.experiment for r in rows} and not mine:
            continue
        run_counts[f"{experiment}/{condition}"] = {
            "planned": planned, "recorded": len(mine), **Counter(r.status for r in mine),
            "flagged": sum(1 for r in mine if r.monitor_status == "flagged"),
            "cleared": sum(1 for r in mine if r.review == "cleared"),
            "void": sum(1 for r in mine if r.review == "void"),
            "pending": sum(1 for r in mine if r.pending),
        }
    sampled = [r for r in rows if r.monitor_status == "certified" and r.review]
    agreement = {}
    for directory in experiment_dirs:
        file = directory / "assessment_agreement.json"
        if file.is_file():
            agreement[directory.name] = json.loads(file.read_text())
    report = {
        "provisional": loaded.provisional, "pending": loaded.pending,
        "experiments": sorted(loaded.experiments), "model": model,
        "prices": {"date": prices.get("date"), "source": prices.get("source")},
        "conditions": conditions, "comparisons": comparisons, "kb": kb_metrics,
        "approaches_compared": len(comparisons),
        "repeat_noise": compare.repeat_noise(_select(baseline, side="B")) if baseline else {},
        "trust": {
            "run_counts": run_counts, "monitor_findings": dict(findings),
            "redteam_caught": (mean(1.0 if r.monitor_status == "flagged" else 0.0 for r in loaded.redteam)
                               if loaded.redteam else None),
            "redteam_runs": len(loaded.redteam),
            "clean_sample_read": len(sampled),
            "clean_sample_voided": (mean(1.0 if r.review == "void" else 0.0 for r in sampled)
                                    if sampled else None),
            "assessment_self_agreement": agreement,
        },
    }

    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "summary.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    _per_task(rows, prices, model, out_dir / "per_task.csv")
    _figure(conditions, out_dir / "figures")
    (out_dir / "report.md").write_text(_markdown(report), encoding="utf-8")
    return report


def _per_task(rows: list[Row], prices: dict, model: str, path: Path) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.writer(handle)
        writer.writerow(["experiment", "condition", "side", "task_id", "module", "category", "runs",
                         "pass_rate", "tokens_mean", "cost_mean", "seconds_mean"])
        keys = sorted({(r.experiment, r.condition, r.side) for r in rows})
        for experiment, condition, side in keys:
            chosen = _select(rows, experiment=experiment, condition=condition, side=side)
            for task_id, task_rows in sorted(by_task(chosen).items()):
                seconds = [r.seconds for r in task_rows if r.seconds is not None]
                writer.writerow([
                    experiment, condition, side, task_id, task_rows[0].group,
                    task_rows[0].tags.get("category", ""), len(task_rows),
                    f"{task_rate(task_rows):.3f}",
                    f"{mean(total_tokens(r.usage) for r in task_rows):.0f}",
                    f"{mean(cost(r.usage, prices, model) for r in task_rows):.4f}",
                    f"{mean(seconds):.1f}" if seconds else "",
                ])


def _figure(conditions: dict, folder: Path) -> None:
    """Pass rate against tokens per run on B, one point per condition."""
    try:
        import matplotlib

        matplotlib.use("Agg")
        import matplotlib.pyplot as plt
    except ImportError:
        return
    points = [(label, sides["B"]) for label, sides in conditions.items()
              if "B" in sides and sides["B"].get("mode") != "build"]
    if not points:
        return
    folder.mkdir(parents=True, exist_ok=True)
    figure, axis = plt.subplots(figsize=(7, 4.5))
    for label, entry in points:
        is_baseline = entry["mode"] == "baseline"
        axis.scatter(entry["tokens_per_run_total"], entry["pass_rate"], s=70 if is_baseline else 40,
                     marker="s" if is_baseline else "o", color="black" if is_baseline else "tab:blue")
        axis.annotate(label, (entry["tokens_per_run_total"], entry["pass_rate"]),
                      textcoords="offset points", xytext=(6, 4), fontsize=7)
    axis.set_xlabel("Tokens per run")
    axis.set_ylabel("Pass rate on B")
    axis.set_ylim(0, 1)
    axis.grid(alpha=0.3)
    figure.tight_layout()
    figure.savefig(folder / "pass_rate_vs_tokens.png", dpi=150)
    plt.close(figure)


def fill_writeup(report_markdown: str, writeup: Path) -> int:
    """Refresh the generated blocks of the written report, so that no number in
    it is typed by hand. A block is

        <!-- generated: Conditions -->
        ...
        <!-- /generated -->

    and is replaced by the section of the generated report whose heading starts
    with that name. Returns the number of blocks filled.
    """
    import re

    sections = {}
    for chunk in report_markdown.split("\n## ")[1:]:
        heading, _, body = chunk.partition("\n")
        sections[heading.strip()] = body.strip()

    def replace(match) -> str:
        name = match.group(1).strip()
        body = next((b for heading, b in sections.items() if heading.startswith(name)), None)
        inner = body if body is not None else "_Not available yet._"
        return f"<!-- generated: {name} -->\n{inner}\n<!-- /generated -->"

    text = writeup.read_text(encoding="utf-8")
    filled, count = re.subn(r"<!-- generated: ([^>]+?) -->.*?<!-- /generated -->", replace, text,
                            flags=re.DOTALL)
    writeup.write_text(filled, encoding="utf-8", newline="\n")
    return count


# -- report.md ---------------------------------------------------------------

def _pct(value) -> str:
    return "" if value is None else f"{100 * value:.1f}%"


def _interval(entry: dict, pct: bool = True, signed: bool = False) -> str:
    if not entry or entry.get("value") is None:
        return ""
    scale, unit = (100, "%") if pct else (1, "")
    sign = "+" if signed else ""
    return (f"{scale * entry['value']:{sign}.1f}{unit} "
            f"({scale * entry['low']:{sign}.1f} to {scale * entry['high']:{sign}.1f})") if pct else (
            f"{entry['value']:.2f} ({entry['low']:.2f} to {entry['high']:.2f})")


def _table(header: list[str], body: list[list]) -> list[str]:
    lines = ["| " + " | ".join(header) + " |", "|" + "---|" * len(header)]
    lines += ["| " + " | ".join(str(c) for c in row) + " |" for row in body]
    return lines + [""]


def _markdown(report: dict) -> str:
    out = ["# Report", ""]
    if report["provisional"]:
        out += [f"**Provisional.** {report['pending']} runs are not yet certified, so results are "
                "by Verdict alone.", ""]
    out += [f"Experiments: {', '.join(report['experiments'])}. Model: `{report['model']}`. "
            f"Prices: {report['prices']['source']}, {report['prices']['date']}.", ""]

    out += ["## Conditions", ""]
    body = []
    for label, sides in report["conditions"].items():
        for side, m in sides.items():
            k = m["repeats"]
            body.append([label, side, m["tasks"], m["runs"], _interval(m["pass_rate_interval"]),
                         _pct(m[f"pass@{k}"]), _pct(m[f"pass^{k}"]),
                         f"{m['tokens_per_run']['input_uncached']:.0f} / "
                         f"{m['tokens_per_run']['input_cached']:.0f} / {m['tokens_per_run']['output']:.0f}",
                         f"${m['cost_per_run']:.3f}",
                         "" if m["cost_per_solved_task"] is None else f"${m['cost_per_solved_task']:.3f}",
                         "" if m["seconds_mean"] is None else f"{m['seconds_mean']:.0f}s",
                         f"{m['responses_per_run']:.1f}", _pct(m["kb_use"])])
    out += _table(["Condition", "Side", "Tasks", "Runs", "Pass rate (95%)", "pass@k", "pass^k",
                   "Tokens per run: uncached / cached / output", "Cost per run",
                   "Cost per solved task", "Time to solution", "Responses", "KB use"], body)

    if report["comparisons"]:
        out += [f"## Approaches against the baseline on B ({report['approaches_compared']} compared)", ""]
        body = []
        for name, entry in report["comparisons"].items():
            versus = entry.get("vs_baseline") or {}
            if not versus.get("tasks"):
                continue
            empty = entry.get("vs_empty_kb") or {}
            body.append([name, versus["tasks"], _interval(versus["pass_rate_difference"], signed=True),
                         f"{versus['helped']} / {versus['harmed']} / {versus['unchanged']}",
                         _interval(versus["token_ratio"], pct=False),
                         _interval(versus["time_ratio"], pct=False),
                         _interval(empty.get("pass_rate_difference"), signed=True),
                         _pct(versus.get("smallest_detectable_difference"))])
        out += _table(["Approach", "Tasks", "Pass rate difference (95%)", "Helped / harmed / unchanged",
                       "Token ratio", "Time ratio", "Difference against its empty KB",
                       "Smallest detectable difference"], body)

        out += ["## Cost of building", ""]
        body = []
        for name, entry in report["kb"].items():
            build, even = entry.get("build_cost") or {}, entry.get("break_even") or {}
            if not build:
                continue
            tasks = even.get("tasks_to_break_even")
            body.append([name, build["chains"], f"{build['tokens']:.0f}", f"${build['dollars']:.2f}",
                         f"{build['seconds'] / 60:.1f} min", _pct(build["contribution_rate"]),
                         "never" if even and tasks is None else ("" if not even else f"{tasks:.0f} tasks")])
        out += _table(["Approach", "Chains", "Extra tokens per chain", "Extra cost per chain",
                       "Extra time per chain", "Contribution rate", "Break-even"], body)

    baseline_b = next((s["B"] for s in report["conditions"].values()
                       if "B" in s and s["B"]["mode"] == "baseline"), None)
    if baseline_b:
        out += ["## By bug category, on B", ""]
        categories = sorted(baseline_b["by_category"])
        body = [[label, *[_pct(sides["B"]["by_category"].get(c)) for c in categories]]
                for label, sides in report["conditions"].items()
                if "B" in sides and sides["B"]["mode"] != "build"]
        out += _table(["Condition", *categories], body)

    rated = {label: sides[side]["limitation_rates"] for label, sides in report["conditions"].items()
             for side in sides if sides[side].get("limitation_rates")}
    if rated:
        out += ["## Limitations", "",
                "From a model's reading of each run, so descriptive only.", ""]
        for name, measured in report["trust"]["assessment_self_agreement"].items():
            if measured.get("runs"):
                out += [f"Read twice, {name}'s reader named the same set of categories for "
                        f"{_pct(measured['same_set'])} of {measured['runs']} runs.", ""]
        categories = sorted({c for rates in rated.values() for c in rates})
        out += _table(["Condition", *categories],
                      [[label, *[_pct(rates.get(c, 0.0)) for c in categories]] for label, rates in rated.items()])
        for name, entry in report["comparisons"].items():
            changes = entry.get("limitations_vs_baseline")
            if changes:
                out += [f"### {name}: resolved / persisting / introduced", ""]
                out += _table(["Category", "Resolved", "Persisting", "Introduced"],
                              [[c, _pct(v["resolved"]), _pct(v["persisting"]), _pct(v["introduced"])]
                               for c, v in changes.items()])

    out += ["## Trust", ""]
    body = [[label, c["planned"], c["recorded"], c.get("completed", 0), c.get("timeout", 0),
             c.get("error", 0), c["flagged"], c["cleared"], c["void"], c["pending"]]
            for label, c in report["trust"]["run_counts"].items()]
    out += _table(["Condition", "Planned", "Recorded", "Completed", "Timed out", "Errored", "Flagged",
                   "Cleared", "Void", "Pending"], body)
    trust = report["trust"]
    if trust["monitor_findings"]:
        out += ["Monitor findings: " + ", ".join(f"{k} {v}" for k, v in sorted(trust["monitor_findings"].items())), ""]
    if trust["redteam_runs"]:
        out += [f"Red-team runs flagged: {_pct(trust['redteam_caught'])} of {trust['redteam_runs']}.", ""]
    noise = report.get("repeat_noise") or {}
    if noise.get("tasks"):
        out += [f"Two repeats of the baseline differ by {_interval(noise['difference'], signed=True)} on B. "
                f"The smallest difference in pass rate this benchmark can tell from chance is about "
                f"{_pct(noise['smallest_detectable_difference'])}.", ""]
    return "\n".join(out)
