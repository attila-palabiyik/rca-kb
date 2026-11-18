"""Drives Harbor and turns what it produces into Trials.

Harbor is known only here and in materialise.py. Each run is one Harbor job
with one trial: a fresh container for the agent, a separate one for grading.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass, field
from pathlib import Path

from harness.config.load import RunSpec, Setup
from harness.dataset.loader import Dataset, Task
from harness.grader import registry

from . import kb as kbstate
from .materialise import SOLVE, UPDATE, Materialised, materialise

HARBOR_VERSION = "0.26.0"
SUPPORTED_AGENTS = ("codex",)
BUILTIN_AGENTS = ("oracle", "nop")         # known-good and do-nothing, for task checks


@dataclass
class Phase:
    name: str
    started: str | None
    ended: str | None
    usage: dict
    trajectory: Path | None
    raw_log: Path | None


@dataclass
class Trial:
    """What the executor returns for one run."""

    run_id: str
    status: str                              # completed | timeout | error
    phases: dict[str, Phase]
    submission: dict[str, Path]
    verdict: dict | None
    exception: dict | None
    output_dir: Path                         # Harbor's trial directory, unmodified
    kb_copy: Path | None = None
    failed_attempts: list[Path] = field(default_factory=list)
    agent_version: str | None = None
    update_ok: bool | None = None            # None when the run had no Update turn


def _usage(agent_result: dict | None, trajectory: Path | None) -> dict:
    result = agent_result or {}
    total_in = result.get("n_input_tokens") or 0
    cached = result.get("n_cache_tokens") or 0
    responses = 0
    if trajectory and trajectory.is_file():
        try:
            steps = json.loads(trajectory.read_text(encoding="utf-8")).get("steps", [])
            responses = sum(1 for s in steps if s.get("source") == "agent")
        except (ValueError, OSError):
            responses = 0
    return {"input_uncached": max(total_in - cached, 0), "input_cached": cached,
            "output": result.get("n_output_tokens") or 0, "responses": responses}


def _first(directory: Path, *names: str) -> Path | None:
    for name in names:
        if (directory / name).is_file():
            return directory / name
    return None


def _phase(name: str, timing: dict | None, agent_result: dict | None, agent_dir: Path) -> Phase:
    trajectory = _first(agent_dir, "trajectory.json")
    timing = timing or {}
    return Phase(name, timing.get("started_at"), timing.get("finished_at"),
                 _usage(agent_result, trajectory), trajectory, _first(agent_dir, "codex.txt"))


def parse_trial(run_id: str, trial_dir: Path, task: Task, steps: list[str]) -> Trial:
    """Read one Harbor trial directory."""
    result = json.loads((trial_dir / "result.json").read_text(encoding="utf-8"))
    names = registry.get(task.grader).submission_files(task)
    phases: dict[str, Phase] = {}
    exception = result.get("exception_info")
    update_ok = None

    if len(steps) == 1:
        phases[SOLVE] = _phase(SOLVE, result.get("agent_execution"), result.get("agent_result"),
                               trial_dir / "agent")
        verifier_dir, artifacts = trial_dir / "verifier", trial_dir / "artifacts"
    else:
        # The run's outcome is Solve's. A failed Update costs only the contribution.
        failures = {}
        for step in result.get("step_results") or []:
            step_dir = trial_dir / "steps" / step["step_name"]
            phases[step["step_name"]] = _phase(step["step_name"], step.get("agent_execution"),
                                               step.get("agent_result"), step_dir / "agent")
            failures[step["step_name"]] = step.get("exception_info")
        if SOLVE in phases:
            exception = failures.get(SOLVE)
        update_ok = UPDATE in phases and failures.get(UPDATE) is None and exception is None
        verifier_dir = trial_dir / "steps" / SOLVE / "verifier"
        artifacts = trial_dir / "steps" / SOLVE / "artifacts"

    submission = {n: artifacts / "app" / n for n in names if (artifacts / "app" / n).is_file()}
    verdict_file = verifier_dir / "verdict.json"
    verdict = json.loads(verdict_file.read_text(encoding="utf-8")) if verdict_file.is_file() else None

    status = "completed"
    if exception:
        kind = str(exception.get("exception_type", ""))
        status = "timeout" if "AgentTimeout" in kind else "error"
    if SOLVE not in phases:
        status = "error"
    return Trial(run_id, status, phases, submission, verdict, exception, trial_dir,
                 agent_version=_agent_version(phases, result), update_ok=update_ok)


def _agent_version(phases: dict[str, Phase], result: dict) -> str | None:
    """The CLI version as the trajectory records it; Harbor's own field as a fallback."""
    solve = phases.get(SOLVE)
    if solve and solve.trajectory:
        try:
            agent = json.loads(solve.trajectory.read_text(encoding="utf-8")).get("agent") or {}
            if agent.get("version"):
                return agent["version"]
        except (ValueError, OSError):
            pass
    return (result.get("agent_info") or {}).get("version")


class HarborExecutor:
    def __init__(self, dataset: Dataset, work_root: Path, harbor: str = "harbor"):
        self.dataset = dataset
        self.work_root = work_root
        self.harbor = harbor

    def check(self, setup: Setup) -> list[str]:
        """Problems that would stop this executor honouring a Setup."""
        problems = []
        if setup.agent.get("name") not in SUPPORTED_AGENTS:
            problems.append(f"agent {setup.agent.get('name')!r} is not supported")
        if setup.network.get("mode", "allowlist") not in ("allowlist", "public", "no-network"):
            problems.append(f"network mode {setup.network.get('mode')!r} is not supported")
        if shutil.which(self.harbor) is None:
            problems.append("harbor is not installed")
        return problems

    def execute(self, run_specs: list[RunSpec], kb: Path | None = None, max_parallel: int = 1,
                retries: int = 0) -> list[Trial]:
        """Run each RunSpec. `kb` is the captured KB state each run gets a copy of."""
        with ThreadPoolExecutor(max_workers=max(1, max_parallel)) as pool:
            return list(pool.map(lambda run: self._with_retries(run, kb, retries), run_specs))

    def _with_retries(self, run: RunSpec, kb: Path | None, retries: int) -> Trial:
        failed: list[Path] = []
        for attempt in range(retries + 1):
            trial = self._execute_once(run, kb, attempt)
            if trial.status != "error":
                break
            if attempt < retries:
                failed.append(trial.output_dir)
        trial.failed_attempts = failed
        return trial

    def _execute_once(self, run: RunSpec, kb: Path | None, attempt: int) -> Trial:
        work = self.work_root / run.run_id / f"attempt-{attempt}"
        if work.exists():
            self._remove(work)
        work.mkdir(parents=True)
        task, setup = self.dataset.tasks[run.task_id], run.setup

        kb_copy = None
        if setup.kb:
            kb_copy = work / "kb"
            source = kb if kb is not None else Path(setup.kb["seed"])
            if source.is_dir():
                shutil.copytree(source, kb_copy, symlinks=True)
            else:
                kb_copy.mkdir()

        with_update = run.condition.mode == "build" and bool(setup.update_prompt.strip())
        built = materialise(task, setup, work / "task", kb_copy=kb_copy, with_update=with_update)
        command = self._agent_command(setup, built, kb_copy)
        trial = self._run_harbor(run.run_id, command, built, task, work)
        trial.kb_copy = kb_copy
        if kb_copy is not None:
            self._collect_cli_sessions(setup, trial, kb_copy)
            self._own(kb_copy, setup.image)
        return trial

    def discard(self, run: RunSpec) -> None:
        """Destroy a finished run's working files, including its KB copy."""
        self._remove(self.work_root / run.run_id)

    def run_builtin(self, task: Task, setup: Setup, agent: str) -> Trial:
        """Run a task with the known-good or the do-nothing agent. No model is called."""
        if agent not in BUILTIN_AGENTS:
            raise ValueError(f"not a built-in agent: {agent}")
        work = self.work_root / "_checks" / agent / task.id
        if work.exists():
            self._remove(work)
        work.mkdir(parents=True)
        built = materialise(task, setup, work / "task")
        return self._run_harbor(f"_checks/{agent}/{task.id}", ["-a", agent], built, task, work)

    def _agent_command(self, setup: Setup, built: Materialised, kb_copy: Path | None) -> list[str]:
        command = ["-a", setup.agent["name"], "-m", f"openai/{setup.model}",
                   "--effort", setup.effort, "--ak", "skip_install=true",
                   "--ak", f"version={setup.agent['version']}"]
        if "web_search" in setup.settings:
            command += ["--ak", f"web_search={setup.settings['web_search']}"]
        if built.agent_config:
            command += ["--ak", f"config={json.dumps(built.agent_config)}"]
        if built.mounts:
            command += ["--mounts", json.dumps(built.mounts)]
        if len(built.steps) > 1:
            command += ["--resume-trajectory"]
        if setup.agent_memory.get("session") == "continue" and kb_copy is not None:
            if (session := self._latest_session(setup, kb_copy)) is not None:
                command += ["--load-trajectory", str(session)]
        return command

    def _run_harbor(self, run_id: str, agent_command: list[str], built: Materialised, task: Task,
                    work: Path) -> Trial:
        jobs = work / "jobs"
        command = [self.harbor, "run", "-p", str(built.task_dir), "-o", str(jobs),
                   "--job-name", "run", "-y", "-q", *agent_command]
        env = dict(os.environ)
        completed = subprocess.run(command, cwd=work, capture_output=True, text=True, env=env)
        (work / "harbor.stdout").write_text(completed.stdout[-20000:], encoding="utf-8")
        (work / "harbor.stderr").write_text(completed.stderr[-20000:], encoding="utf-8")
        trial_dirs = [p.parent for p in (jobs / "run").glob("*/result.json")] if jobs.exists() else []
        if not trial_dirs:
            return Trial(run_id, "error", {}, {}, None,
                         {"exception_type": "HarborFailed",
                          "exception_message": (completed.stderr or completed.stdout)[-2000:]},
                         work)
        return parse_trial(run_id, trial_dirs[0], task, built.steps)

    # -- what the agent CLI writes itself ---------------------------------

    @staticmethod
    def _sessions_dir(setup: Setup, kb_copy: Path) -> Path | None:
        subdir = setup.kb.get("cli_sessions")
        return kb_copy / subdir if subdir else None

    def _latest_session(self, setup: Setup, kb_copy: Path) -> Path | None:
        sessions = self._sessions_dir(setup, kb_copy)
        if sessions is None or not sessions.is_dir():
            return None
        rollouts = sorted(sessions.rglob("rollout-*.jsonl"), key=lambda p: p.stat().st_mtime)
        return rollouts[-1] if rollouts else None

    def _collect_cli_sessions(self, setup: Setup, trial: Trial, kb_copy: Path) -> None:
        """Keep the transcripts the CLI saved in the part of the KB set aside for them."""
        sessions = self._sessions_dir(setup, kb_copy)
        saved = trial.output_dir / "agent" / "sessions"
        if sessions is None or trial.status != "completed" or not saved.is_dir():
            return
        if setup.agent_memory.get("session") == "continue" and sessions.exists():
            shutil.rmtree(sessions, ignore_errors=True)      # one session, carried forward
        sessions.mkdir(parents=True, exist_ok=True)
        for rollout in saved.rglob("rollout-*.jsonl"):
            shutil.copy2(rollout, sessions / rollout.name)

    # -- files the container wrote as root --------------------------------

    def _own(self, path: Path, image: str) -> None:
        subprocess.run(["docker", "run", "--rm", "-v", f"{path}:/target", image, "chown", "-R",
                        f"{os.getuid()}:{os.getgid()}", "/target"], capture_output=True)

    def _remove(self, path: Path) -> None:
        shutil.rmtree(path, ignore_errors=True)
        if path.exists():
            subprocess.run(["docker", "run", "--rm", "-v", f"{path.parent}:/target",
                            "ubuntu:24.04", "rm", "-rf", f"/target/{path.name}"], capture_output=True)
