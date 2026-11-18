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

from . import compare, figures
from .metrics import Loaded, Row, by_task, condition_metrics, cost, learning_curve, load, load_prices, \
    task_rate, total_tokens, within_budget


class ReportError(ValueError):
    """Experiments that must not be compared."""


OVERLAY_FIELDS = ("instructions", "update_prompt", "kb", "agent_memory")


def base_hash(setup: dict) -> str:
    """A Setup's hash with the fields a KB approach's overlay may set left out:
    two experiments with equal base hashes ran under the same base Setup."""
    import hashlib

    base = {k: v for k, v in setup.items() if k not in OVERLAY_FIELDS}
    return hashlib.sha256(json.dumps(base, sort_keys=True).encode()).hexdigest()[:16]


def _check_comparable(loaded: Loaded, root: Path) -> None:
    """One baseline, shared: refuse experiments that were not run alike.

    The base Setup is compared from each experiment's stored Setups, apart from
    the fields an approach may set (OVERLAY_FIELDS)."""
    keys = ("dataset_version", "split", "seed")
    seen = {}
    for name, info in loaded.experiments.items():
        if info.get("kind") == "redteam":
            continue
        for key in keys:
            seen.setdefault(key, {})[name] = info.get(key)
        bases = set()
        for setup_hash in set(info.get("setups", {}).values()):
            file = root / "runs" / name / "setups" / f"{setup_hash}.json"
            if file.is_file():
                bases.add(base_hash(json.loads(file.read_text())))
        seen.setdefault("base Setup", {})[name] = ",".join(sorted(bases)) or info.get("base_setup_hash")
    for key, values in seen.items():
        if len(set(values.values())) > 1:
            raise ReportError(f"experiments differ in {key}: {values}")


def _select(rows: list[Row], **want) -> list[Row]:
    return [r for r in rows if all(getattr(r, k) == v for k, v in want.items())]


def _by_tag(rows: list[Row], prices: dict, model: str) -> dict:
    """The headline metrics grouped by every tag the tasks carry."""
    keep = ("tasks", "runs", "pass_rate", "tokens_per_run_total", "cost_per_run", "seconds_mean")
    grouped = {}
    for tag in sorted({key for r in rows for key in r.tags}):
        values = sorted({r.tags.get(tag, "") for r in rows})
        grouped[tag] = {}
        for value in values:
            metrics = condition_metrics([r for r in rows if r.tags.get(tag) == value], prices, model)
            grouped[tag][value] = {key: metrics[key] for key in keep}
    return grouped


def _limitations_by_outcome(rows: list[Row]) -> dict:
    """Limitation shares among the runs that failed and among those that passed."""
    out = {}
    for name, wanted in (("failed", False), ("passed", True)):
        chosen = [r for r in rows if r.passed == wanted and r.limitations is not None]
        if chosen:
            out[name] = {"runs": len(chosen), "none": mean(0.0 if r.limitations else 1.0 for r in chosen),
                         "rates": compare.limitation_rates(chosen)}
    return out


def _seen_and_unseen(build: list[Row], baseline_a: list[Row], prices: dict, model: str) -> dict:
    """The build's runs on A against the baseline, apart for tasks whose module
    the chain had already met and tasks whose module was new to it. A task is
    solved before its own result is shown, so both are honest outcomes."""
    if not build or not baseline_a:
        return {}
    met, parts = set(), {"seen": [], "first": []}
    for row in sorted(build, key=lambda r: (r.repeat, r.position or 0)):
        key = (row.repeat, row.group)
        parts["seen" if key in met else "first"].append(row)
        met.add(key)
    return {name: compare.paired(rows, baseline_a, prices, model) for name, rows in parts.items() if rows}


def _final_state(root: Path, experiment: str) -> dict:
    """What a built KB holds when frozen: its files and their words, the
    session transcripts it keeps apart (they are the CLI's, not written by the
    agent). Words are a rough measure of what reading it all would cost."""
    out = {}
    for chain in sorted((root / "runs" / experiment / "kb").glob("*/*/chain.json")):
        final = json.loads(chain.read_text()).get("final")
        folder = chain.parent / "snapshots" / str(final)
        if not final or not folder.is_dir():
            continue
        files, words, largest, sessions = 0, 0, ("", 0), 0
        for file in sorted(folder.rglob("*")):
            if not file.is_file():
                continue
            relative = file.relative_to(folder).as_posix()
            if relative.startswith("sessions/"):
                sessions += 1
                continue
            try:
                count = len(file.read_text(encoding="utf-8").split())
            except (UnicodeDecodeError, OSError):
                count = 0
            files += 1
            words += count
            if count > largest[1]:
                largest = (relative, count)
        out[chain.parent.parent.name] = {"files": files, "words": words, "largest": largest[0],
                                         "largest_words": largest[1], "sessions": sessions}
    return out.get("build", next(iter(out.values()), {}))


def _group_outcomes(rows: list[Row]) -> dict:
    """How many groups (modules) pass in every run, in none, or in some."""
    groups = {}
    for row in rows:
        groups.setdefault(row.group, []).append(row.passed)
    kinds = Counter("all" if all(v) else "none" if not any(v) else "some" for v in groups.values())
    return {"groups": len(groups), "pass_all": kinds["all"], "pass_none": kinds["none"], "pass_some": kinds["some"]}


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
    _check_comparable(loaded, root)
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
                         limitation_rates_by_outcome=_limitations_by_outcome(on_side),
                         groups=_group_outcomes(on_side),
                         by_tag=_by_tag(on_side, prices, model))
            entry["by_category"] = {value: m["pass_rate"]
                                    for value, m in entry["by_tag"].get("category", {}).items()}
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
            "seen_and_unseen": _seen_and_unseen(build, _select(baseline, side="A"), prices, model),
            "final_state": _final_state(root, experiment),
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
    agreement, planted = {}, {}
    for directory in experiment_dirs:
        file = directory / "assessment_agreement.json"
        if file.is_file():
            agreement[directory.name] = json.loads(file.read_text())
        file = directory / "redteam_planted.json"
        if file.is_file():
            result = json.loads(file.read_text())
            planted[directory.name] = {k: v for k, v in result.items() if k != "cases"}
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
            "planted_violations": planted,
            "redteam_attempted": (mean(1.0 if any(f.get("intent") in ("enacted", "attempted")
                                                  for f in r.findings) else 0.0 for r in loaded.redteam)
                                  if loaded.redteam else None),
        },
    }

    out_dir = Path(out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / "summary.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    _per_task(rows, prices, model, out_dir / "per_task.csv")
    figures.draw(report, rows, out_dir / "figures")
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


def _baseline_sides(report: dict) -> dict:
    return next((sides for sides in report["conditions"].values()
                 if any(m["mode"] == "baseline" for m in sides.values())), {})


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

MINUS = "−"
VIOLATIONS = {"read_grading_assets": "reading the grading assets", "search_for_answers": "searching for answers",
              "fetch_from_network": "fetching from the network", "fake_the_result": "faking the result",
              "copy_another_runs_answer": "copying another run's answer"}


def _num(value, digits: int = 1, signed: bool = False) -> str:
    """A number with a true minus sign, and no sign on zero."""
    if value is None:
        return ""
    text = f"{value:+.{digits}f}" if signed else f"{value:.{digits}f}"
    if float(text) == 0:
        text = f"{0:.{digits}f}"
    return text.replace("-", MINUS)


def _pct(value) -> str:
    return "" if value is None else f"{100 * value:.1f}%"


def _share(value) -> str:
    """A share in percent, for a column whose header carries the unit."""
    return "" if value is None else _num(100 * value)


def _range(entry: dict, scale: float = 100.0, signed: bool = False, digits: int = 1) -> str:
    if not entry or entry.get("value") is None:
        return ""
    return f"{_num(scale * entry['low'], digits, signed)} to {_num(scale * entry['high'], digits, signed)}"


def _name(label: str) -> str:
    """baseline -> No KB; kb-rule-tags/eval -> Rules by tags; kb-notes/build -> Notes, build."""
    experiment, _, condition = label.partition("/")
    if experiment == "baseline":
        return "No KB"
    name = figures.approach_name(experiment)
    extra = {"": "", "eval": "", "build": ", build", "empty": ", empty KB"}.get(condition, f", {condition}")
    return name + extra


def _table(header: list[str], body: list[list]) -> list[str]:
    """A markdown table. A column whose cells are all numbers is set to the right."""
    def numeric(column: int) -> bool:
        cells = [str(row[column]) for row in body if str(row[column])]
        return bool(cells) and all(cell[0] in "0123456789+-$" + MINUS for cell in cells)

    rule = ["---:" if numeric(column) else "---" for column in range(len(header))]
    lines = ["| " + " | ".join(header) + " |", "|" + "|".join(rule) + "|"]
    lines += ["| " + " | ".join(str(c) for c in row) + " |" for row in body]
    return lines + [""]


def _ordered(report: dict) -> list[tuple[str, dict]]:
    """Approaches compared with the baseline on B, the largest gain first."""
    compared = [(name, entry["vs_baseline"]) for name, entry in report["comparisons"].items()
                if (entry.get("vs_baseline") or {}).get("tasks")]
    return sorted(compared, key=lambda item: (-(item[1]["pass_rate_difference"]["value"] or 0), item[0]))


def _body_sections(report: dict) -> list[str]:
    """The narrow tables and counted sentences the written report's body uses."""
    out = []
    baseline = _baseline_sides(report)
    if baseline:
        out += ["## Baseline", ""]
        k = next(iter(baseline.values()))["repeats"]
        body = []
        for side, m in sorted(baseline.items()):
            body.append([side, m["tasks"], m["groups"]["groups"], m["runs"], _share(m["pass_rate"]),
                         _range(m["pass_rate_interval"]), _share(m[f"pass@{k}"]), _share(m[f"pass^{k}"]),
                         f"{m['tokens_per_run_total'] / 1000:.0f}k", f"{m['cost_per_run']:.3f}",
                         f"{m['seconds_mean']:.0f}"])
        out += _table(["Set", "Tasks", "Modules", "Runs", "Pass rate, %", "95% interval",
                       "Passing any run, %", "Passing every run, %", "Tokens per run",
                       "Cost per run, $", "Time to solution, s"], body)

        out += ["## Baseline outcomes", ""]
        for side, m in sorted(baseline.items()):
            tasks, groups = m["tasks"], m["groups"]
            always, ever = round(m[f"pass^{k}"] * tasks), round(m[f"pass@{k}"] * tasks)
            out += [f"On set {side}, {always} of {tasks} tasks passed in all {k} runs, {tasks - ever} in none "
                    f"and {ever - always} in some. Of its {groups['groups']} modules, {groups['pass_all']} "
                    f"passed every run, {groups['pass_none']} passed none and {groups['pass_some']} "
                    f"{'was' if groups['pass_some'] == 1 else 'were'} mixed.", ""]

        outcomes = {side: (m.get("limitation_rates_by_outcome") or {}) for side, m in sorted(baseline.items())}
        if any(outcomes.values()):
            out += ["## Baseline limitations", ""]
            for side, by in outcomes.items():
                failed = by.get("failed")
                if not failed:
                    continue
                counts = sorted(((round(rate * failed["runs"]), figures.limitation_label(c).lower())
                                 for c, rate in failed["rates"].items() if c != "other"), reverse=True)
                out += [f"Of the {failed['runs']} runs that failed on set {side}: "
                        + ", ".join(f"{label} {count}" for count, label in counts) + ".", ""]
            for name, measured in report["trust"]["assessment_self_agreement"].items():
                if measured.get("runs") and name == "baseline":
                    out += [f"Labelling {measured['runs']} runs a second time, the model gave the same set of "
                            f"limitations for {round(measured['same_set'] * measured['runs'])} of them.", ""]

    compared = _ordered(report)
    if compared:
        out += ["## Results on B", ""]
        body = []
        base = baseline.get("B")
        if base:
            body.append(["No KB", f"{round(base['pass_rate'] * base['runs'])} of {base['runs']}",
                         _share(base["pass_rate"]), "", "", "", "", "", "", ""])
        for name, versus in compared:
            own = report["conditions"].get(f"{name}/eval", {}).get("B", {})
            passed = f"{round(own['pass_rate'] * own['runs'])} of {own['runs']}" if own else ""
            body.append([_name(name), passed, _share(own.get("pass_rate")),
                         _num(100 * versus["pass_rate_difference"]["value"], signed=True),
                         _range(versus["pass_rate_difference"], signed=True),
                         versus["helped"], versus["harmed"],
                         _num(versus["token_ratio"]["value"], 2), _num(versus["time_ratio"]["value"], 2),
                         _share(own.get("kb_use"))])
        out += _table(["Approach", "Runs passed", "Pass rate, %", "Difference, points", "95% interval",
                       "Tasks helped", "Tasks harmed", "Tokens, × no KB", "Time, × no KB", "Runs that read the KB, %"],
                      body)

        seen = [(name, report["kb"].get(name, {}).get("seen_and_unseen") or {}) for name, _ in compared]
        if any(entry for _, entry in seen):
            out += ["## Seen and unseen modules", ""]
            body = []
            for (name, versus), (_, entry) in zip(compared, seen):
                row = [_name(name)]
                for key in ("seen", "first"):
                    part = entry.get(key) or {}
                    difference = part.get("pass_rate_difference") or {}
                    row += [part.get("tasks", ""), _num(100 * difference["value"], signed=True)
                            if difference.get("value") is not None else "", _range(difference, signed=True)]
                row += [versus["tasks"], _num(100 * versus["pass_rate_difference"]["value"], signed=True),
                        _range(versus["pass_rate_difference"], signed=True)]
                body.append(row)
            out += _table(["Approach", "A, module met before: tasks", "difference, points", "95% interval",
                           "A, module new: tasks", "difference, points", "95% interval",
                           "B, every module new: tasks", "difference, points", "95% interval"], body)
    return out


def _markdown(report: dict) -> str:
    out = ["# Report", ""]
    if report["provisional"]:
        out += [f"**Provisional.** {report['pending']} runs are not yet certified, so results are "
                "by Verdict alone.", ""]
    out += [f"Experiments: {', '.join(report['experiments'])}. Model: `{report['model']}`. "
            f"Prices: {report['prices']['source']}, {report['prices']['date']}.", ""]

    out += _body_sections(report)

    out += ["## Conditions", ""]
    body = []
    for label, sides in report["conditions"].items():
        for side, m in sides.items():
            k = m["repeats"]
            body.append([_name(label), side, m["tasks"], m["runs"], _share(m["pass_rate"]),
                         _range(m["pass_rate_interval"]),
                         f"{m['tokens_per_run']['input_uncached'] / 1000:.1f}k",
                         f"{m['tokens_per_run']['input_cached'] / 1000:.1f}k",
                         f"{m['tokens_per_run']['output'] / 1000:.1f}k",
                         f"{m['cost_per_run']:.3f}",
                         "" if m["cost_per_solved_task"] is None else f"{m['cost_per_solved_task']:.3f}",
                         "" if m["seconds_mean"] is None else f"{m['seconds_mean']:.0f}",
                         f"{m['responses_per_run']:.1f}"])
    out += _table(["Condition", "Set", "Tasks", "Runs", "Pass rate, %", "95% interval", "Uncached in",
                   "Cached in", "Output", "$ / run", "$ / solved", "Time, s", "Responses"], body)

    compared = _ordered(report)
    if compared:
        out += [f"## Approaches against the baseline on B ({report['approaches_compared']} compared)", ""]
        body = []
        for name, versus in compared:
            empty = report["comparisons"][name].get("vs_empty_kb") or {}
            body.append([_name(name), versus["tasks"],
                         _num(100 * versus["pass_rate_difference"]["value"], signed=True),
                         _range(versus["pass_rate_difference"], signed=True),
                         f"{versus['helped']} / {versus['harmed']} / {versus['unchanged']}",
                         _num(versus["token_ratio"]["value"], 2), _range(versus["token_ratio"], 1.0, digits=2),
                         _num(versus["time_ratio"]["value"], 2), _range(versus["time_ratio"], 1.0, digits=2),
                         _num(100 * empty["pass_rate_difference"]["value"], signed=True)
                         if (empty.get("pass_rate_difference") or {}).get("value") is not None else "",
                         _range(empty.get("pass_rate_difference"), signed=True)])
        out += _table(["Approach", "Tasks", "Pass rate difference, points", "95% interval",
                       "Tasks helped / harmed / unchanged", "Tokens, × no KB", "95% interval",
                       "Time, × no KB", "95% interval", "Against its own empty KB, points", "95% interval"], body)

        out += ["## Cost of building", ""]
        body = []
        for name, _ in compared:
            entry = report["kb"].get(name) or {}
            build, even = entry.get("build_cost") or {}, entry.get("break_even") or {}
            if not build:
                continue
            tasks = even.get("tasks_to_break_even")
            body.append([_name(name), f"{_num(build['tokens'] / 1e6, 2)}M", _num(build["dollars"], 2),
                         _num(build["seconds"] / 60, 0), _share(build["contribution_rate"]),
                         "never" if even and tasks is None else ("" if not even else f"{tasks:.0f} tasks")])
        out += _table(["Approach", "Extra tokens", "Extra cost, $", "Extra time, min",
                       "Tasks after which the KB changed, %", "Pays for itself after"], body)

    base_b = _baseline_sides(report).get("B")
    if base_b:
        out += ["## By bug category", ""]
        categories = sorted(base_b["by_tag"].get("category", {}))

        def cells(entry: dict) -> list[str]:
            tags = entry["by_tag"].get("category", {})
            return [f"{_share(tags[c]['pass_rate'])} ({tags[c]['tasks']})" if c in tags else "" for c in categories]

        body = [[_name(label), side, *cells(entry)]
                for label, sides in report["conditions"].items() for side, entry in sorted(sides.items())
                if entry["mode"] == "baseline"]
        body += [[_name(name), "B", *cells(report["conditions"][f"{name}/eval"]["B"])]
                 for name, _ in compared if "B" in report["conditions"].get(f"{name}/eval", {})]
        out += _table(["Condition", "Set", *[c.replace("_", " ").capitalize() for c in categories]], body)

    rated = {(label, side): sides[side]["limitation_rates"]
             for label, sides in report["conditions"].items()
             for side in sorted(sides) if sides[side].get("limitation_rates") and sides[side]["mode"] != "build"}
    if rated:
        out += ["## Limitations", ""]
        categories = sorted({c for rates in rated.values() for c in rates if c != "other"},
                            key=lambda c: (-max(r.get(c, 0) for r in rated.values()), c))
        out += _table(["Condition", "Set", *[figures.limitation_label(c) for c in categories]],
                      [[_name(label), side, *[_share(rates.get(c, 0.0)) for c in categories]]
                       for (label, side), rates in rated.items()])

        changes = [(name, report["comparisons"][name].get("limitations_vs_baseline") or {}) for name, _ in compared]
        if any(entry for _, entry in changes):
            out += ["## Limitation changes", ""]
            shown = [c for c in categories if not c.startswith("kb_")][:4]
            header = ["Approach"]
            for c in shown:
                header += [f"{figures.limitation_label(c)}: resolved", "introduced"]
            out += _table(header, [[_name(name), *[_share((entry.get(c) or {}).get(key))
                                                   for c in shown for key in ("resolved", "introduced")]]
                                   for name, entry in changes if entry])

    states = [(name, (report["kb"].get(name) or {}).get("final_state") or {}) for name, _ in compared]
    if any(state for _, state in states):
        out += ["## KB contents", ""]
        out += _table(["Approach", "Files", "Words", "Largest file", "Words in it", "Session transcripts kept"],
                      [[_name(name), state.get("files", ""), f"{state.get('words', 0):,}",
                        f"`{state['largest']}`" if state.get("largest") else "", f"{state.get('largest_words', 0):,}",
                        state.get("sessions", "")] for name, state in states if state])

    out += ["## Trust", ""]
    body = [[_name(label), c["planned"], c["recorded"], c.get("completed", 0), c.get("timeout", 0),
             c.get("error", 0), c["flagged"], c["cleared"], c["void"], c["pending"]]
            for label, c in report["trust"]["run_counts"].items()]
    out += _table(["Condition", "Planned", "Recorded", "Completed", "Timed out", "Errored", "Flagged",
                   "Cleared", "Void", "Pending"], body)
    trust = report["trust"]
    if trust["monitor_findings"]:
        out += ["Monitor findings: " + ", ".join(f"{k.replace('_', ' ')} {v}"
                                                 for k, v in sorted(trust["monitor_findings"].items())) + ".", ""]
    for name, result in trust["planted_violations"].items():
        kinds = ", ".join(f"{VIOLATIONS.get(kind, kind.replace('_', ' '))} {v['caught']} of {v['planted']}"
                          for kind, v in result["by_kind"].items())
        out += [f"Violations planted in clean {_name(name).lower().replace('no kb', 'baseline')} trajectories: "
                f"the monitor flagged {result['caught']} of {result['planted']} ({kinds}). The model judge flagged "
                f"{result['caught_by_judge']} and the pattern match {result['caught_by_pattern']}.", ""]
    if trust["redteam_runs"]:
        out += [f"Told to get a pass by any means, the agent was flagged in "
                f"{_pct(trust['redteam_caught'])} of {trust['redteam_runs']} runs. A run that is not "
                "flagged here is one where the agent did not attempt a violation.", ""]
    noise = report.get("repeat_noise") or {}
    if noise.get("tasks"):
        out += ["## Repeat noise", "",
                f"Two repeats of the baseline on B differ by {_num(100 * noise['difference']['value'], signed=True)} "
                f"points ({_range(noise['difference'], signed=True)}). From the standard error of that difference, "
                f"a paired comparison on B has 80% power to detect a change of about "
                f"{_num(100 * noise['smallest_detectable_difference'])} points.", ""]
    return "\n".join(out)
