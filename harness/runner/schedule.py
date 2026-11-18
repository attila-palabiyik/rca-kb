"""Runs an experiment: batches in parallel, chains one run at a time.

A batch is a set of independent runs. A chain is an ordered list of runs that
share one KB: each run works on a copy of the latest snapshot, and if the run
stands with a contribution, its copy becomes the next snapshot. Restarting an
experiment skips whatever is already recorded.
"""

from __future__ import annotations

import json
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from harness.config.load import Experiment, RunSpec
from harness.records import store

from . import kb as kbstate
from .executor import HarborExecutor, Trial


def _chain_dir(root: Path, experiment: str, condition: str, repeat: int) -> Path:
    return store.experiment_dir(root, experiment) / "kb" / condition / str(repeat)


def _read_chain(directory: Path) -> dict:
    file = directory / "chain.json"
    return json.loads(file.read_text(encoding="utf-8")) if file.is_file() else {}


def _write_chain(directory: Path, state: dict) -> None:
    directory.mkdir(parents=True, exist_ok=True)
    (directory / "chain.json").write_text(json.dumps(state, indent=2) + "\n", encoding="utf-8")


def _contributed(trial: Trial) -> bool:
    """Whether the run stands and left something to keep."""
    return trial.status == "completed" and trial.update_ok is not False


def run_chain(root: Path, experiment: Experiment, executor: HarborExecutor, chain: list[RunSpec],
              log=print) -> str:
    """Build one KB by running a chain. Returns the final state's ID."""
    first = chain[0]
    directory = _chain_dir(root, experiment.name, first.condition.name, first.repeat)
    snapshots = directory / "snapshots"
    seed_id = kbstate.snapshot(Path(first.setup.kb["seed"]), snapshots)
    state = _read_chain(directory) or {"order": [r.task_id for r in chain], "runs": [], "final": None}
    done = {entry["task_id"]: entry for entry in state["runs"]}
    current = state["runs"][-1]["after"] if state["runs"] else seed_id

    for run in chain:
        if run.task_id in done and store.is_recorded(root, run):
            continue
        before = current
        trial = executor.execute([run], kb=snapshots / before, retries=experiment.retries)[0]
        after = kbstate.snapshot(trial.kb_copy, snapshots) if _contributed(trial) else before
        store.write_run(root, experiment, run, trial, kb_before=before, kb_after=after)
        current = after
        state["runs"].append({"task_id": run.task_id, "before": before, "after": after,
                              "status": trial.status})
        _write_chain(directory, state)
        executor.discard(run)
        log(f"{run.run_id}: {trial.status}, verdict "
            f"{(trial.verdict or {}).get('result')}, kb {before[:6]} -> {after[:6]}")

    state["final"] = current
    _write_chain(directory, state)
    return current


def _frozen_state(root: Path, experiment: Experiment, run: RunSpec) -> tuple[Path | None, str | None]:
    """The captured KB state an eval run gets a copy of, and its ID."""
    if run.condition.mode != "eval":
        return None, None
    if run.condition.snapshot == "seed":
        seed = Path(run.setup.kb["seed"])
        return seed, kbstate.identify(seed)
    directory = _chain_dir(root, experiment.name, run.condition.snapshot, run.repeat)
    final = _read_chain(directory).get("final")
    if not final:
        raise RuntimeError(f"{run.run_id}: chain {run.condition.snapshot}/{run.repeat} is not finished")
    return directory / "snapshots" / final, final


def run_batch(root: Path, experiment: Experiment, executor: HarborExecutor, batch: list[RunSpec],
              log=print) -> None:
    pending = [run for run in batch if not store.is_recorded(root, run)]

    def one(run: RunSpec) -> None:
        state, state_id = _frozen_state(root, experiment, run)
        trial = executor.execute([run], kb=state, retries=experiment.retries)[0]
        # A frozen KB is a private copy that is thrown away: before and after are the same.
        store.write_run(root, experiment, run, trial, kb_before=state_id, kb_after=state_id)
        executor.discard(run)
        log(f"{run.run_id}: {trial.status}, verdict {(trial.verdict or {}).get('result')}")

    with ThreadPoolExecutor(max_workers=max(1, experiment.max_parallel)) as pool:
        list(pool.map(one, pending))


def run_experiment(root: Path, experiment: Experiment, executor: HarborExecutor,
                   conditions: set[str] | None = None, log=print) -> None:
    """Chains first, since frozen runs depend on what they build; then batches."""
    store.init_experiment(root, experiment)
    chains = [c for c in experiment.chains if conditions is None or c[0].condition.name in conditions]
    batches = [b for b in experiment.batches if b and (conditions is None or b[0].condition.name in conditions)]
    if chains:
        with ThreadPoolExecutor(max_workers=max(1, min(len(chains), experiment.max_parallel))) as pool:
            list(pool.map(lambda chain: run_chain(root, experiment, executor, chain, log), chains))
    for batch in batches:
        run_batch(root, experiment, executor, batch, log)
