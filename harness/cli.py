"""Command line for the harness.

    python -m harness.cli convert chipbench --source .cache/chipbench --commit <hash>
    python -m harness.cli split chipbench --seed 1
    python -m harness.cli check-tasks chipbench
    python -m harness.cli run configs/experiments/baseline.toml
    python -m harness.cli monitor baseline
    python -m harness.cli assess baseline
    python -m harness.cli flagged baseline
    python -m harness.cli review baseline/baseline/0/<task> cleared --note "..."
    python -m harness.cli report baseline kb-notes --out reports/main
    python -m harness.cli archive baseline
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from harness.config.load import load_base, load_experiment
from harness.dataset.loader import load_dataset
from harness.dataset.split import draw_split, write_split
from harness.runner.executor import HarborExecutor
from harness.runner.schedule import run_experiment

ROOT = Path.cwd()


def work_root() -> Path:
    return Path(os.environ.get("RCAKB_WORK", Path.home() / ".cache" / "rcakb" / "work"))


def cmd_convert(args) -> int:
    from harness.dataset.adapters import chipbench

    adapters = {"chipbench": chipbench}
    out = ROOT / "datasets" / args.dataset
    skipped = adapters[args.dataset].convert(args.source, out, args.commit)
    dataset = load_dataset(out)
    print(f"{len(dataset.tasks)} tasks written to {out}; version {dataset.version}")
    for line in skipped:
        print(f"left out: {line}")
    return 0


def cmd_split(args) -> int:
    dataset = load_dataset(ROOT / "datasets" / args.dataset)
    split = draw_split(dataset, args.seed, args.name)
    path = write_split(dataset, split)
    print(f"{path}: A {len(split.a)} tasks, B {len(split.b)} tasks")
    return 0


def cmd_check_tasks(args) -> int:
    """The known-good answer must pass and the untouched workspace must fail."""
    dataset = load_dataset(ROOT / "datasets" / args.dataset)
    setup = load_base(ROOT / "configs")
    executor = HarborExecutor(dataset, work_root())
    tasks = [dataset.tasks[t] for t in (args.tasks or sorted(dataset.tasks))]
    checks_file = dataset.root / "checks.json"
    checks = json.loads(checks_file.read_text()) if checks_file.is_file() else {}

    def one(task):
        outcome = {}
        for label, agent, expected in (("known_good", "oracle", "pass"), ("do_nothing", "nop", "fail")):
            trial = executor.run_builtin(task, setup, agent)
            verdict = trial.verdict or {}
            outcome[label] = {"result": verdict.get("result", trial.status),
                              "reason": verdict.get("reason"), "expected": expected}
        outcome["ok"] = all(v["result"] == v["expected"] for v in outcome.values())
        print(f"{'ok  ' if outcome['ok'] else 'FAIL'} {task.id}: "
              f"known-good {outcome['known_good']['result']}, do-nothing {outcome['do_nothing']['result']}",
              flush=True)
        return task.id, outcome

    started = time.time()
    with ThreadPoolExecutor(max_workers=args.parallel) as pool:
        checks.update(dict(pool.map(one, tasks)))
    checks_file.write_text(json.dumps(dict(sorted(checks.items())), indent=2) + "\n")
    failed = [t for t, c in checks.items() if not c["ok"]]
    print(f"{len(checks) - len(failed)} of {len(checks)} tasks pass both checks "
          f"({time.time() - started:.0f}s); failing: {failed}")
    return 0 if not failed else 1


def cmd_run(args) -> int:
    probe = HarborExecutor(None, work_root())
    experiment = load_experiment(args.experiment, ROOT, check_setup=probe.check)
    executor = HarborExecutor(experiment.dataset, work_root())
    planned = sum(map(len, experiment.batches)) + sum(map(len, experiment.chains))
    print(f"{experiment.name}: {planned} runs planned, {experiment.max_parallel} at once", flush=True)

    def log(line: str) -> None:
        print(f"[{time.strftime('%H:%M:%S')}] {line}", flush=True)

    run_experiment(ROOT, experiment, executor, set(args.conditions) if args.conditions else None, log)
    return 0


def cmd_monitor(args) -> int:
    from harness.monitor.monitor import monitor_experiment_dir

    return monitor_experiment_dir(ROOT, args.experiment, args.parallel, args.limit, args.force,
                                  args.rubric)


def cmd_assess(args) -> int:
    from harness.monitor.assess import assess_experiment_dir

    return assess_experiment_dir(ROOT, args.experiment, args.parallel, args.limit, args.force,
                                 second_reading=args.second_reading)


def cmd_redteam(args) -> int:
    """Plant known violations in certified trajectories and count what the monitor flags."""
    from harness.monitor.redteam import run_planted

    result = run_planted(ROOT, args.experiment, args.per_kind, args.parallel, args.rubric)
    print(json.dumps({k: v for k, v in result.items() if k != "cases"}, indent=2))
    return 0 if result["caught"] == result["planted"] else 1


def cmd_notes(args) -> int:
    """Free-text notes on a sample of A's runs, from which the categories are drawn."""
    from harness.dataset.loader import load_split
    from harness.monitor.assess import notes_for_sample
    from harness.records import store

    info = store.load_experiment_info(ROOT / "runs" / args.experiment)
    dataset = load_dataset(ROOT / "datasets" / info["dataset"])
    split = load_split(dataset, info["split"])
    out = ROOT / "reports" / "assessment-notes" / f"{args.experiment}.json"
    notes = notes_for_sample(ROOT, args.experiment, split.a, out, args.sample, args.parallel)
    print(f"{len(notes)} notes written to {out}")
    return 0


def cmd_regrade(args) -> int:
    """Grade every stored Submission again and compare with the stored Verdict."""
    from harness.grader.regrade import regrade, same_verdict
    from harness.records import store

    directory = ROOT / "runs" / args.experiment
    info = store.load_experiment_info(directory)
    dataset = load_dataset(ROOT / "datasets" / info["dataset"])
    image = load_base(ROOT / "configs").image
    runs = [r for r in store.load_runs(directory) if r.status != "error"]

    def one(run) -> bool:
        verdict = regrade(dataset.tasks[run.task_id], run.directory / "submission", image)
        identical = same_verdict(run.verdict, verdict)
        if not identical:
            print(f"DIFFERS {run.run_id}: stored {(run.verdict or {}).get('result')}/"
                  f"{(run.verdict or {}).get('reason')}, now {verdict['result']}/{verdict['reason']}",
                  flush=True)
            if args.replace:
                store.write_derived(run, "verdict.json", verdict)
        return identical

    with ThreadPoolExecutor(max_workers=args.parallel) as pool:
        outcomes = list(pool.map(one, runs))
    print(f"{args.experiment}: {sum(outcomes)} of {len(outcomes)} Submissions regraded to an identical Verdict")
    return 0 if all(outcomes) else 1


def cmd_flagged(args) -> int:
    """What a person has to read: flagged runs awaiting review, or a sample of certified ones."""
    import random

    from harness.records import store

    runs = store.load_runs(ROOT / "runs" / args.experiment)
    if args.sample:
        certified = [r for r in runs if (r.monitor or {}).get("status") == "certified" and not r.review]
        chosen = random.Random(1).sample(certified, min(args.sample, len(certified)))
        for run in sorted(chosen, key=lambda r: r.run_id):
            print(run.run_id)
        return 0
    for run in runs:
        if (run.monitor or {}).get("status") == "flagged" and not run.review:
            print(run.run_id)
            for finding in run.monitor["findings"]:
                print(f"    {finding['source']}: {finding['category']} ({finding['intent']}) "
                      f"at step {finding['step']}: {finding['quote'][:100]!r}")
    return 0


def cmd_review(args) -> int:
    from harness.records import store

    experiment = args.run_id.split("/")[0]
    store.write_review(ROOT / "runs" / experiment, args.run_id, args.decision, args.note)
    print(f"{args.run_id}: {args.decision}")
    return 0


def cmd_archive(args) -> int:
    """Pack an experiment's raw logs and trajectories into one archive, and record its checksum."""
    import hashlib
    import tarfile

    directory = ROOT / "runs" / args.experiment
    out = ROOT / "archives" / f"{args.experiment}-trials.tar.gz"
    out.parent.mkdir(exist_ok=True)
    # The session transcripts a KB keeps: the final snapshot of each chain holds them all.
    sessions = []
    for chain in directory.glob("kb/*/*/chain.json"):
        final = json.loads(chain.read_text()).get("final")
        if final and (chain.parent / "snapshots" / final / "sessions").is_dir():
            sessions.append(chain.parent / "snapshots" / final / "sessions")
    with tarfile.open(out, "w:gz") as archive:
        for folder in sorted([*directory.glob("*/*/*/trial"), *directory.glob("*/*/*/attempts"), *sessions]):
            archive.add(folder, arcname=folder.relative_to(ROOT).as_posix())
    digest = hashlib.sha256(out.read_bytes()).hexdigest()
    (directory / "trials.sha256").write_text(f"{digest}  {out.name}\n")
    print(f"{out} ({out.stat().st_size / 1e6:.1f} MB), sha256 {digest[:16]}...")
    return 0


def cmd_report(args) -> int:
    from harness.report.render import build_report

    from harness.report.render import fill_writeup

    directories = [ROOT / "runs" / name for name in args.experiments]
    build_report(directories, ROOT / "configs" / "prices.toml", ROOT / args.out)
    print(f"report written to {args.out}")
    if args.write_up:
        generated = (ROOT / args.out / "report.md").read_text(encoding="utf-8")
        blocks = fill_writeup(generated, ROOT / args.write_up)
        print(f"{blocks} generated blocks refreshed in {args.write_up}")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="harness")
    commands = parser.add_subparsers(dest="command", required=True)

    convert = commands.add_parser("convert", help="convert a benchmark into the task format")
    convert.add_argument("dataset", choices=["chipbench"])
    convert.add_argument("--source", required=True)
    convert.add_argument("--commit", required=True)
    convert.set_defaults(run=cmd_convert)

    split = commands.add_parser("split", help="draw a split by group")
    split.add_argument("dataset")
    split.add_argument("--seed", type=int, default=1)
    split.add_argument("--name", default="main")
    split.set_defaults(run=cmd_split)

    check = commands.add_parser("check-tasks", help="known-good passes, do-nothing fails")
    check.add_argument("dataset")
    check.add_argument("--tasks", nargs="*")
    check.add_argument("--parallel", type=int, default=4)
    check.set_defaults(run=cmd_check_tasks)

    run = commands.add_parser("run", help="run an experiment file")
    run.add_argument("experiment")
    run.add_argument("--conditions", nargs="*")
    run.set_defaults(run=cmd_run)

    for name, function, text in (("monitor", cmd_monitor, "review every run of an experiment"),
                                 ("assess", cmd_assess, "assess every run of an experiment")):
        sub = commands.add_parser(name, help=text)
        sub.add_argument("experiment")
        sub.add_argument("--parallel", type=int, default=8)
        sub.add_argument("--limit", type=int)
        sub.add_argument("--force", action="store_true", help="redo runs that already have one")
        if name == "monitor":
            sub.add_argument("--rubric", help="use this rubric version instead of the experiment's")
        if name == "assess":
            sub.add_argument("--second-reading", type=int, default=0,
                             help="read this many runs twice, to measure the reader's agreement with itself")
        sub.set_defaults(run=function)

    redteam = commands.add_parser("redteam", help="test the monitor with planted violations")
    redteam.add_argument("experiment")
    redteam.add_argument("--per-kind", type=int, default=3)
    redteam.add_argument("--parallel", type=int, default=8)
    redteam.add_argument("--rubric")
    redteam.set_defaults(run=cmd_redteam)

    notes = commands.add_parser("notes", help="free-text notes on a sample of A's runs")
    notes.add_argument("experiment")
    notes.add_argument("--sample", type=int, default=30)
    notes.add_argument("--parallel", type=int, default=8)
    notes.set_defaults(run=cmd_notes)

    regrade = commands.add_parser("regrade", help="grade stored Submissions again and compare")
    regrade.add_argument("experiment")
    regrade.add_argument("--parallel", type=int, default=8)
    regrade.add_argument("--replace", action="store_true",
                         help="store the new Verdict where it differs")
    regrade.set_defaults(run=cmd_regrade)

    flagged = commands.add_parser("flagged", help="list flagged runs awaiting a person's review")
    flagged.add_argument("experiment")
    flagged.add_argument("--sample", type=int, default=0,
                         help="list a sample of certified runs to read instead")
    flagged.set_defaults(run=cmd_flagged)

    review = commands.add_parser("review", help="record a person's decision on a run")
    review.add_argument("run_id")
    review.add_argument("decision", choices=["cleared", "void"])
    review.add_argument("--note", default="")
    review.set_defaults(run=cmd_review)

    archive = commands.add_parser("archive", help="pack an experiment's trajectories into one archive")
    archive.add_argument("experiment")
    archive.set_defaults(run=cmd_archive)

    report = commands.add_parser("report", help="build a report from stored runs")
    report.add_argument("experiments", nargs="+")
    report.add_argument("--out", required=True)
    report.add_argument("--write-up", help="a written report whose generated blocks to refresh")
    report.set_defaults(run=cmd_report)

    args = parser.parse_args(argv)
    return args.run(args)


if __name__ == "__main__":
    sys.exit(main())
