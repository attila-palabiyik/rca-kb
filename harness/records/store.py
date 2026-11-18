"""Stores every run and loads it back.

The runner writes through this module. Every other component reads runs only
through `load_run` and `load_runs`; the layout under `runs/` is private.
Raw artifacts are written once; `record.json` is written last, and a run
directory without it is incomplete.
"""

from __future__ import annotations

import json
import shutil
import subprocess
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path

from harness.config.load import Experiment, RunSpec
from harness.runner.executor import HARBOR_VERSION, Trial


def _json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2, default=str) + "\n", encoding="utf-8", newline="\n")


def _read(path: Path, default=None):
    return json.loads(path.read_text(encoding="utf-8")) if path.is_file() else default


def harness_commit(root: Path) -> str:
    out = subprocess.run(["git", "-C", str(root), "rev-parse", "HEAD"], capture_output=True, text=True)
    return out.stdout.strip() if out.returncode == 0 and out.stdout.strip() else "uncommitted"


def experiment_dir(root: Path, name: str) -> Path:
    return root / "runs" / name


def run_dir(root: Path, run: RunSpec) -> Path:
    return root / "runs" / run.run_id


def is_recorded(root: Path, run: RunSpec) -> bool:
    return (run_dir(root, run) / "record.json").is_file()


def init_experiment(root: Path, experiment: Experiment) -> Path:
    """Write the facts shared by every run of an experiment."""
    directory = experiment_dir(root, experiment.name)
    for name, setup in experiment.setups.items():
        _json(directory / "setups" / f"{setup.hash}.json", setup.to_dict())
    info_file = directory / "experiment.json"
    if not info_file.exists():
        baseline = next((s for n, s in experiment.setups.items()
                         if not s.kb), next(iter(experiment.setups.values())))
        _json(info_file, {
            "name": experiment.name, "kind": experiment.kind, "resolved": experiment.resolved,
            "dataset": experiment.dataset.name, "dataset_version": experiment.dataset.version,
            "split": experiment.split.name, "seed": experiment.seed,
            "harness_commit": harness_commit(root), "base_setup_hash": baseline.hash,
            "executor": {"name": "harbor", "version": HARBOR_VERSION},
            "started": datetime.now(timezone.utc).isoformat(),
            "max_parallel": experiment.max_parallel,
            "setups": {name: setup.hash for name, setup in experiment.setups.items()},
        })
    return directory


def write_run(root: Path, experiment: Experiment, run: RunSpec, trial: Trial,
              kb_before: str | None = None, kb_after: str | None = None) -> Path:
    """Store one finished run. `record.json` goes last."""
    directory = run_dir(root, run)
    if directory.exists():
        shutil.rmtree(directory)
    directory.mkdir(parents=True)

    if trial.output_dir.is_dir():
        shutil.copytree(trial.output_dir, directory / "trial", symlinks=True)
    for index, failed in enumerate(trial.failed_attempts):
        if failed.is_dir():
            shutil.copytree(failed, directory / "attempts" / str(index), symlinks=True)
    for name, source in trial.submission.items():
        (directory / "submission").mkdir(exist_ok=True)
        shutil.copy2(source, directory / "submission" / name)
    if trial.verdict is not None:
        _json(directory / "verdict.json", trial.verdict)

    def relative(path: Path) -> str:
        return (Path("trial") / path.relative_to(trial.output_dir)).as_posix()

    phases = {}
    for name, phase in trial.phases.items():
        phases[name] = {
            "started": phase.started, "ended": phase.ended, "usage": phase.usage,
            "trajectory": relative(phase.trajectory) if phase.trajectory else None,
            "raw_log": relative(phase.raw_log) if phase.raw_log else None,
        }
    _json(directory / "record.json", {
        "run_id": run.run_id, "experiment": run.experiment,
        "condition": {"name": run.condition.name, "mode": run.condition.mode,
                      "kb": run.condition.kb, "snapshot": run.condition.snapshot},
        "task_id": run.task_id, "repeat": run.repeat, "position": run.position,
        "provenance": {
            "dataset_version": experiment.dataset.version, "setup_hash": run.setup.hash,
            "harness_commit": harness_commit(root), "agent_version": trial.agent_version,
            "executor_version": HARBOR_VERSION,
        },
        "status": trial.status, "attempts": len(trial.failed_attempts) + 1,
        "exception": trial.exception, "phases": phases,
        "kb": {"before": kb_before, "after": kb_after,
               "changed": kb_before is not None and kb_before != kb_after},
    })
    return directory


@dataclass
class Run:
    """One run, as stored."""

    directory: Path
    record: dict
    verdict: dict | None
    monitor: dict | None
    assessment: dict | None
    review: dict | None
    tags: dict = field(default_factory=dict)

    @property
    def run_id(self) -> str:
        return self.record["run_id"]

    @property
    def task_id(self) -> str:
        return self.record["task_id"]

    @property
    def condition(self) -> str:
        return self.record["condition"]["name"]

    @property
    def mode(self) -> str:
        return self.record["condition"]["mode"]

    @property
    def repeat(self) -> int:
        return self.record["repeat"]

    @property
    def status(self) -> str:
        return self.record["status"]

    def usage(self, phase: str = "solve") -> dict:
        return (self.record["phases"].get(phase) or {}).get("usage") or {}

    def seconds(self, phase: str = "solve") -> float | None:
        info = self.record["phases"].get(phase) or {}
        if not info.get("started") or not info.get("ended"):
            return None
        started = datetime.fromisoformat(info["started"].replace("Z", "+00:00"))
        ended = datetime.fromisoformat(info["ended"].replace("Z", "+00:00"))
        return (ended - started).total_seconds()

    def trajectory(self, phase: str = "solve") -> dict | None:
        relative = (self.record["phases"].get(phase) or {}).get("trajectory")
        return _read(self.directory / relative) if relative else None

    def submission(self) -> dict[str, str]:
        folder = self.directory / "submission"
        if not folder.is_dir():
            return {}
        return {p.name: p.read_text(encoding="utf-8", errors="replace") for p in sorted(folder.iterdir())}

    @property
    def verdict_result(self) -> str:
        """The grader's word alone, before any certification: pass, fail or pending."""
        if self.status in ("timeout", "error"):
            return "fail"
        if self.verdict is None or self.verdict.get("result") == "error":
            return "pending"
        return self.verdict["result"]

    @property
    def result(self) -> str:
        """The one rule that turns a run into pass, fail or pending."""
        if self.review and self.review.get("decision") == "void":
            return "fail"
        outcome = self.verdict_result
        if outcome != "pass":
            return outcome
        if self.monitor is None:
            return "pending"                                  # not yet monitored
        if self.monitor.get("status") == "certified":
            return "pass"
        if self.review and self.review.get("decision") == "cleared":
            return "pass"
        return "pending"                                      # flagged, awaiting review


def load_run(directory: str | Path, reviews: dict | None = None) -> Run:
    directory = Path(directory)
    record = _read(directory / "record.json")
    if record is None:
        raise FileNotFoundError(f"not a recorded run: {directory}")
    if reviews is None:
        reviews = _read(directory.parents[2] / "reviews.json", {})
    return Run(directory, record, _read(directory / "verdict.json"),
               _read(directory / "monitor.json"), _read(directory / "assessment.json"),
               reviews.get(record["run_id"]))


def load_runs(experiment_directory: str | Path) -> list[Run]:
    directory = Path(experiment_directory)
    reviews = _read(directory / "reviews.json", {})
    records = sorted(directory.glob("*/*/*/record.json"))
    return [load_run(p.parent, reviews) for p in records if p.parts[-4] != "kb"]


def load_experiment_info(experiment_directory: str | Path) -> dict:
    return _read(Path(experiment_directory) / "experiment.json", {})


def write_derived(run: Run, name: str, data: dict) -> None:
    """Replace a derived file (monitor.json, assessment.json); raw artifacts stay."""
    _json(run.directory / name, data)
