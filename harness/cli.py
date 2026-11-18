"""Command line for the harness.

    python -m harness.cli convert chipbench --source .cache/chipbench --commit <hash>
    python -m harness.cli split chipbench --seed 1
    python -m harness.cli check-tasks chipbench
    python -m harness.cli run configs/experiments/baseline.toml
    python -m harness.cli monitor baseline
    python -m harness.cli assess baseline
    python -m harness.cli report baseline notes --out reports/main
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

    return monitor_experiment_dir(ROOT, args.experiment, args.parallel, args.limit)


def cmd_assess(args) -> int:
    from harness.monitor.assess import assess_experiment_dir

    return assess_experiment_dir(ROOT, args.experiment, args.parallel, args.limit)


def cmd_report(args) -> int:
    from harness.report.render import build_report

    directories = [ROOT / "runs" / name for name in args.experiments]
    build_report(directories, ROOT / "configs" / "prices.toml", ROOT / args.out)
    print(f"report written to {args.out}")
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
        sub.set_defaults(run=function)

    report = commands.add_parser("report", help="build a report from stored runs")
    report.add_argument("experiments", nargs="+")
    report.add_argument("--out", required=True)
    report.set_defaults(run=cmd_report)

    args = parser.parse_args(argv)
    return args.run(args)


if __name__ == "__main__":
    sys.exit(main())
