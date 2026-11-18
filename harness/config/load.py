"""Loads, validates and resolves configuration.

The only code that reads config files. Everything else receives resolved
objects: a Setup says what an agent is given, a RunSpec is one run to execute,
and an Experiment is the batches and chains of RunSpecs one file expands to.
"""

from __future__ import annotations

import copy
import hashlib
import json
import random
import tomllib
from dataclasses import asdict, dataclass, field
from pathlib import Path

from harness.dataset.loader import Dataset, Split, load_dataset, load_split
from harness.grader import registry


class ConfigError(ValueError):
    """A config file that is malformed or breaks a rule."""


PROTECTED = ("agent", "model", "effort", "image", "limits", "network", "rules")
OVERLAY_KEYS = ("instructions", "update_prompt", "files", "mcp_servers", "settings", "agent_memory", "kb")
MODES = ("baseline", "build", "eval")
EXPERIMENT_KEYS = ("dataset", "split", "repeats", "seed", "max_parallel", "retries", "tasks",
                   "monitor", "conditions", "kind")
CONDITION_KEYS = ("name", "mode", "kb", "side", "snapshot")
AGENT_MEMORY = {"builtin": ("off", "on"), "session": ("fresh", "continue")}


@dataclass(frozen=True)
class Setup:
    """Everything the agent is given, fully resolved."""

    agent: dict
    model: str
    effort: str
    image: str
    limits: dict
    network: dict
    rules: str
    instructions: str = ""
    update_prompt: str = ""
    files: tuple = ()
    mcp_servers: tuple = ()
    settings: dict = field(default_factory=dict)
    agent_memory: dict = field(default_factory=dict)
    kb: dict = field(default_factory=dict)

    def to_dict(self) -> dict:
        return json.loads(json.dumps(asdict(self)))

    @property
    def hash(self) -> str:
        blob = json.dumps(self.to_dict(), sort_keys=True).encode()
        return hashlib.sha256(blob).hexdigest()[:16]

    def first_turn(self, task_instructions: str) -> str:
        """Turn one: the rules, then the task, then the approach's instructions."""
        parts = [self.rules.strip(), task_instructions.strip(), self.instructions.strip()]
        return "\n\n".join(p for p in parts if p) + "\n"


@dataclass(frozen=True)
class Condition:
    name: str
    mode: str
    side: tuple
    kb: str | None = None
    snapshot: str | None = None


@dataclass(frozen=True)
class RunSpec:
    run_id: str
    experiment: str
    condition: Condition
    task_id: str
    repeat: int
    setup: Setup
    position: int | None = None      # place in its chain, for build runs


@dataclass
class Experiment:
    name: str
    kind: str
    dataset: Dataset
    split: Split
    repeats: int
    seed: int
    max_parallel: int
    retries: int
    monitor: dict
    conditions: list[Condition]
    setups: dict[str, Setup]         # condition name -> resolved Setup
    batches: list[list[RunSpec]]
    chains: list[list[RunSpec]]
    resolved: dict                   # the experiment file as read


def _toml(path: Path) -> dict:
    with path.open("rb") as handle:
        return tomllib.load(handle)


def load_base(configs: Path) -> Setup:
    data = _toml(configs / "base.toml")
    try:
        return Setup(
            agent=data["agent"], model=data["model"], effort=data["effort"], image=data["image"],
            limits=data["limits"], network=data["network"],
            rules=(configs / data["rules"]).read_text(encoding="utf-8"),
            settings=data.get("settings", {}),
            agent_memory=data.get("agent_memory", {"builtin": "off", "session": "fresh"}),
        )
    except KeyError as missing:
        raise ConfigError(f"base.toml: missing {missing}") from None


def _joined(kb_dir: Path, value) -> str:
    """Instruction text: an ordered list of files under configs/kb/, joined."""
    names = [value] if isinstance(value, str) else list(value)
    texts = []
    for name in names:
        path = kb_dir / name
        if not path.is_file():
            raise ConfigError(f"instruction piece not found: {path}")
        texts.append(path.read_text(encoding="utf-8").strip())
    return "\n\n".join(texts)


def _leaf_paths(table: dict, prefix: str = "") -> set[str]:
    paths = set()
    for key, value in table.items():
        if isinstance(value, dict):
            paths |= _leaf_paths(value, f"{prefix}{key}.")
        else:
            paths.add(f"{prefix}{key}")
    return paths


def _merge(into: dict, extra: dict) -> dict:
    for key, value in extra.items():
        if isinstance(value, dict) and isinstance(into.get(key), dict):
            _merge(into[key], value)
        else:
            into[key] = copy.deepcopy(value)
    return into


def apply_overlay(base: Setup, configs: Path, approach: str) -> Setup:
    """The base Setup with one KB approach's Overlay applied."""
    kb_dir = configs / "kb"
    approach_dir = kb_dir / approach
    overlay_file = approach_dir / "overlay.toml"
    if not overlay_file.is_file():
        raise ConfigError(f"no KB approach named {approach!r}")
    overlay = _toml(overlay_file)
    for key in overlay:
        if key in PROTECTED:
            raise ConfigError(f"{approach}: an overlay may not change {key!r}")
        if key not in OVERLAY_KEYS:
            raise ConfigError(f"{approach}: unknown overlay key {key!r}")

    settings = copy.deepcopy(base.settings)
    extra = overlay.get("settings", {})
    if clash := _leaf_paths(extra) & _leaf_paths(base.settings):
        raise ConfigError(f"{approach}: overlay overrides base settings {sorted(clash)}")
    _merge(settings, extra)

    memory = dict(base.agent_memory)
    for key, value in overlay.get("agent_memory", {}).items():
        if value not in AGENT_MEMORY.get(key, ()):
            raise ConfigError(f"{approach}: agent_memory.{key} = {value!r} is not valid")
        memory[key] = value

    files = []
    for entry in overlay.get("files", []):
        source = approach_dir / "files" / entry["source"]
        if not source.exists():
            raise ConfigError(f"{approach}: file not found: {source}")
        files.append({"source": str(source), "target": entry["target"]})

    kb = {"backend": "directory", "path": "/kb", "seed": str(approach_dir / "seed")}
    kb.update(overlay.get("kb", {}))
    if kb["backend"] != "directory":
        raise ConfigError(f"{approach}: KB backend {kb['backend']!r} is not implemented")

    return Setup(
        agent=base.agent, model=base.model, effort=base.effort, image=base.image,
        limits=base.limits, network=base.network, rules=base.rules,
        instructions=_joined(kb_dir, overlay.get("instructions", [])),
        update_prompt=_joined(kb_dir, overlay.get("update_prompt", [])),
        files=tuple(files), mcp_servers=tuple(overlay.get("mcp_servers", [])),
        settings=settings, agent_memory=memory, kb=kb,
    )


def chain_order(task_ids: list[str], seed: int, chain: int) -> list[str]:
    """The order of A in chain k: from the seed and k alone, never the approach."""
    order = sorted(task_ids)
    random.Random(f"{seed}:{chain}").shuffle(order)
    return order


def load_experiment(path: str | Path, root: str | Path = ".", check_setup=None) -> Experiment:
    """Read one experiment file and expand it into batches and chains of RunSpecs.

    `check_setup(setup) -> list[str]` lets the executor reject a Setup it
    cannot honour.
    """
    path, root = Path(path), Path(root)
    configs = root / "configs"
    data = _toml(path)
    name = path.stem
    for key in data:
        if key not in EXPERIMENT_KEYS:
            raise ConfigError(f"{name}: unknown key {key!r}")

    dataset = load_dataset(root / "datasets" / data["dataset"])
    split = load_split(dataset, data["split"])
    for task in dataset.tasks.values():
        try:
            problems = registry.get(task.grader).check_task(task)
        except KeyError as unknown:
            raise ConfigError(f"{task.id}: {unknown}") from None
        if problems:
            raise ConfigError(f"{task.id}: grader {task.grader} rejects it: {problems}")

    base = load_base(configs)
    repeats, seed = int(data.get("repeats", 3)), int(data.get("seed", 1))
    only = set(data["tasks"]) if "tasks" in data else None
    if only and (unknown := only - set(dataset.tasks)):
        raise ConfigError(f"{name}: unknown tasks {sorted(unknown)}")
    # Tasks that failed a task check (section 4) are left out until fixed.
    checks_file = dataset.root / "checks.json"
    checks = json.loads(checks_file.read_text(encoding="utf-8")) if checks_file.is_file() else {}
    excluded = sorted(t for t, outcome in checks.items() if not outcome.get("ok"))

    conditions, setups = [], {}
    for raw in data.get("conditions", []):
        for key in raw:
            if key not in CONDITION_KEYS:
                raise ConfigError(f"{name}: unknown condition key {key!r}")
        condition = Condition(raw["name"], raw["mode"], tuple(raw.get("side", ["B"])),
                              raw.get("kb"), raw.get("snapshot"))
        if condition.mode not in MODES:
            raise ConfigError(f"{name}/{condition.name}: unknown mode {condition.mode!r}")
        if condition.mode == "baseline":
            if condition.kb or condition.snapshot:
                raise ConfigError(f"{name}/{condition.name}: a baseline has no KB")
            setup = base
        else:
            if not condition.kb:
                raise ConfigError(f"{name}/{condition.name}: {condition.mode} needs a kb")
            setup = apply_overlay(base, configs, condition.kb)
        if condition.mode == "eval" and not condition.snapshot:
            raise ConfigError(f"{name}/{condition.name}: eval needs a snapshot")
        if check_setup and (problems := check_setup(setup)):
            raise ConfigError(f"{name}/{condition.name}: the executor cannot honour it: {problems}")
        conditions.append(condition)
        setups[condition.name] = setup

    builds = {c.name: c for c in conditions if c.mode == "build"}
    for condition in conditions:
        if condition.mode == "eval" and condition.snapshot != "seed":
            source = builds.get(condition.snapshot)
            if source is None:
                raise ConfigError(f"{name}/{condition.name}: snapshot {condition.snapshot!r} "
                                  "is neither 'seed' nor a build condition in this file")
            if source.kb != condition.kb:
                raise ConfigError(f"{name}/{condition.name}: snapshot comes from a different KB")

    def tasks_on(sides: tuple) -> list[str]:
        ids = [t for side in sides for t in split.side(side)]
        return [t for t in ids if (only is None or t in only) and t not in excluded]

    def spec(condition: Condition, task_id: str, repeat: int, position=None) -> RunSpec:
        run_id = f"{name}/{condition.name}/{repeat}/{task_id}"
        return RunSpec(run_id, name, condition, task_id, repeat, setups[condition.name], position)

    batches, chains = [], []
    for condition in conditions:
        if condition.mode == "build":
            for k in range(repeats):
                order = chain_order(tasks_on(condition.side), seed, k)
                chains.append([spec(condition, t, k, i) for i, t in enumerate(order)])
        else:
            batches.append([spec(condition, t, r) for r in range(repeats)
                            for t in sorted(tasks_on(condition.side))])

    return Experiment(
        name=name, kind=data.get("kind", "results"), dataset=dataset, split=split,
        repeats=repeats, seed=seed, max_parallel=int(data.get("max_parallel", 4)),
        retries=int(data.get("retries", 2)), monitor=data.get("monitor", {}),
        conditions=conditions, setups=setups, batches=batches, chains=chains,
        resolved={**data, "excluded_tasks": excluded},
    )
