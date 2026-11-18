"""Prints the numbers the written report's prose cites, from the generated report.

    python scripts/facts.py [reports/main]

Every figure quoted in the Summary, Results and Discussion should be one this
prints, so that the prose and the tables cannot disagree.
"""

from __future__ import annotations

import csv
import json
import sys
from collections import defaultdict
from pathlib import Path

folder = Path(sys.argv[1] if len(sys.argv) > 1 else "reports/main")
summary = json.loads((folder / "summary.json").read_text())
rows = list(csv.DictReader((folder / "per_task.csv").open(encoding="utf-8")))


def pts(entry: dict | None) -> str:
    if not entry or entry.get("value") is None:
        return "n/a"
    return f"{100 * entry['value']:+.1f} ({100 * entry['low']:+.1f} to {100 * entry['high']:+.1f})"


def ratio(entry: dict | None) -> str:
    if not entry or entry.get("value") is None:
        return "n/a"
    return f"{entry['value']:.2f} ({entry['low']:.2f} to {entry['high']:.2f})"


print(f"provisional: {summary['provisional']}, runs not yet certified: {summary['pending']}")
base = summary["conditions"]["baseline"]
for side in ("A", "B"):
    m = base[side]
    print(f"baseline {side}: pass {100 * m['pass_rate']:.1f}%, tokens {m['tokens_per_run_total']:.0f}, "
          f"${m['cost_per_run']:.3f}/run, {m['seconds_mean']:.0f} s")
noise = summary.get("repeat_noise") or {}
print(f"repeat noise on B: {pts(noise.get('difference'))}, detectable ~{100 * noise.get('smallest_detectable_difference', 0):.1f} pts")

# Which B modules never pass with no KB, and which approaches pass any of their tasks.
baseline_task = {r["task_id"]: float(r["pass_rate"]) for r in rows if r["experiment"] == "baseline" and r["side"] == "B"}
module_of = {r["task_id"]: r["module"] for r in rows}
never = {m for m in set(module_of[t] for t in baseline_task)
         if all(baseline_task[t] == 0 for t in baseline_task if module_of[t] == m)}
print(f"B modules that never pass with no KB: {len(never)}")

ordered = sorted(((n, c["vs_baseline"]) for n, c in summary["comparisons"].items() if c.get("vs_baseline")),
                 key=lambda item: -(item[1]["pass_rate_difference"]["value"] or 0))
excluding = sum(1 for _, v in ordered if v["pass_rate_difference"]["low"] > 0)
print(f"\n{len(ordered)} approaches compared; intervals excluding zero: {excluding}\n")
for name, v in ordered:
    own = summary["conditions"].get(f"{name}/eval", {}).get("B", {})
    kb = summary["kb"].get(name, {})
    build, even, seen, state = (kb.get("build_cost") or {}, kb.get("break_even") or {},
                                kb.get("seen_and_unseen") or {}, kb.get("final_state") or {})
    flipped = sorted({module_of[r["task_id"]] for r in rows
                      if r["experiment"] == name and r["condition"] == "eval" and r["side"] == "B"
                      and float(r["pass_rate"]) > 0 and module_of[r["task_id"]] in never})
    passed = round(own.get("pass_rate", 0) * own.get("runs", 0))
    print(f"{name}")
    print(f"  B: {passed} of {own.get('runs')} ({100 * own.get('pass_rate', 0):.1f}%), diff {pts(v['pass_rate_difference'])}, "
          f"helped {v['helped']}, harmed {v['harmed']}")
    print(f"  tokens x{ratio(v['token_ratio'])}, cost x{ratio(v['cost_ratio'])}, time x{ratio(v['time_ratio'])}, "
          f"KB read in {100 * own['kb_use']:.0f}% of B runs" if own.get("kb_use") is not None else
          f"  tokens x{ratio(v['token_ratio'])}, cost x{ratio(v['cost_ratio'])}, time x{ratio(v['time_ratio'])}")
    print(f"  never-passing modules it passed a task of: {len(flipped)} {flipped}")
    if seen:
        print(f"  A, module met before: {pts((seen.get('seen') or {}).get('pass_rate_difference'))}; "
              f"A, module new: {pts((seen.get('first') or {}).get('pass_rate_difference'))}")
    if build:
        print(f"  build: extra {build['tokens'] / 1e6:.2f}M tokens, ${build['dollars']:.2f}, {build['seconds'] / 60:.0f} min; "
              f"pays back: {even.get('tasks_to_break_even')}")
    if state:
        print(f"  frozen KB: {state.get('files')} files, {state.get('words')} words, {state.get('sessions')} sessions")
    changes = summary["comparisons"][name].get("limitations_vs_baseline") or {}
    for category in ("changed_more_than_the_bug", "test_did_not_test", "missed_the_bug"):
        c = changes.get(category)
        if c:
            print(f"  {category}: resolved {100 * c['resolved']:.1f}, introduced {100 * c['introduced']:.1f}")
