"""Draws a split by group, so tasks that share an answer stay on one side."""

from __future__ import annotations

import json
import random
from collections import Counter
from pathlib import Path

from .loader import Dataset, Split, validate_split


def draw_split(dataset: Dataset, seed: int, name: str = "main") -> Split:
    """Shuffle the groups and give the first half to A."""
    groups = sorted({dataset.group_of(t) for t in dataset.tasks})
    random.Random(seed).shuffle(groups)
    to_a = set(groups[: (len(groups) + 1) // 2])
    task_ids = sorted(dataset.tasks)
    split = Split(
        name,
        [t for t in task_ids if dataset.group_of(t) in to_a],
        [t for t in task_ids if dataset.group_of(t) not in to_a],
        seed,
    )
    validate_split(dataset, split)
    return split


def write_split(dataset: Dataset, split: Split) -> Path:
    def by_category(task_ids: list[str]) -> dict[str, int]:
        counts = Counter(dataset.tasks[t].tags.get("category", "") for t in task_ids)
        return dict(sorted(counts.items()))

    path = dataset.root / "splits" / f"{split.name}.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "A": split.a,
        "B": split.b,
        "seed": split.seed,
        "tasks_per_category": {"A": by_category(split.a), "B": by_category(split.b)},
    }
    path.write_text(json.dumps(payload, indent=2) + "\n", encoding="utf-8")
    return path
