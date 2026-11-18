"""Reads a dataset in the harness's task format and validates it."""

from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from pathlib import Path


class DatasetError(ValueError):
    """A dataset or split that does not satisfy the format."""


@dataclass(frozen=True)
class Task:
    id: str
    grader: str
    tags: dict[str, str]
    root: Path

    @property
    def public(self) -> Path:
        return self.root / "public"

    @property
    def private(self) -> Path:
        return self.root / "private"

    @property
    def instructions(self) -> str:
        return (self.public / "instructions.md").read_text(encoding="utf-8")

    @property
    def workspace(self) -> Path:
        return self.public / "workspace"


@dataclass(frozen=True)
class Dataset:
    name: str
    root: Path
    meta: dict
    tasks: dict[str, Task]
    version: str

    @property
    def group_tag(self) -> str | None:
        return self.meta.get("group_tag")

    def group_of(self, task_id: str) -> str:
        """The value that marks tasks sharing an answer; the task itself if none."""
        tag = self.group_tag
        return self.tasks[task_id].tags.get(tag, task_id) if tag else task_id


@dataclass(frozen=True)
class Split:
    name: str
    a: list[str]
    b: list[str]
    seed: int | None = None

    def side(self, name: str) -> list[str]:
        return {"A": self.a, "B": self.b}[name]


def _version(root: Path) -> str:
    digest = hashlib.sha256()
    files = [root / "dataset.json", *sorted((root / "tasks").rglob("*"))]
    for path in files:
        if path.is_file():
            digest.update(path.relative_to(root).as_posix().encode())
            digest.update(b"\0")
            digest.update(path.read_bytes())
            digest.update(b"\0")
    return digest.hexdigest()[:16]


def load_dataset(path: str | Path) -> Dataset:
    root = Path(path)
    meta = json.loads((root / "dataset.json").read_text(encoding="utf-8"))
    tasks: dict[str, Task] = {}
    for task_dir in sorted((root / "tasks").iterdir()):
        if not task_dir.is_dir():
            continue
        task_file = task_dir / "task.json"
        for required in (task_file, task_dir / "public", task_dir / "private"):
            if not required.exists():
                raise DatasetError(f"{task_dir.name}: missing {required.name}")
        info = json.loads(task_file.read_text(encoding="utf-8"))
        grader = info.get("grader") or meta.get("grader")
        if not grader:
            raise DatasetError(f"{task_dir.name}: resolves to no grader")
        if info["id"] in tasks:
            raise DatasetError(f"task id is not unique: {info['id']}")
        tasks[info["id"]] = Task(info["id"], grader, dict(info.get("tags", {})), task_dir)
    return Dataset(meta["name"], root, meta, tasks, _version(root))


def load_split(dataset: Dataset, name: str) -> Split:
    data = json.loads((dataset.root / "splits" / f"{name}.json").read_text(encoding="utf-8"))
    split = Split(name, list(data["A"]), list(data["B"]), data.get("seed"))
    validate_split(dataset, split)
    return split


def validate_split(dataset: Dataset, split: Split) -> None:
    for task_id in [*split.a, *split.b]:
        if task_id not in dataset.tasks:
            raise DatasetError(f"split {split.name}: unknown task {task_id}")
    if shared := set(split.a) & set(split.b):
        raise DatasetError(f"split {split.name}: A and B share tasks {sorted(shared)}")
    groups_a = {dataset.group_of(t) for t in split.a}
    groups_b = {dataset.group_of(t) for t in split.b}
    if shared := groups_a & groups_b:
        raise DatasetError(f"split {split.name}: A and B share groups {sorted(shared)}")
