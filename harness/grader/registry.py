"""Looks a grader up by the name a dataset or task gives.

A grader is a method, not a benchmark: a package under `graders/` with a
`check` module (host side) and a `grade.py` program (container side).
"""

from __future__ import annotations

import importlib
from pathlib import Path
from types import ModuleType

GRADERS_DIR = Path(__file__).parent / "graders"


def names() -> list[str]:
    return sorted(p.name for p in GRADERS_DIR.iterdir() if (p / "grade.py").is_file())


def get(name: str) -> ModuleType:
    """The grader's host-side module: check_task, submission_files, known_good."""
    if name not in names():
        raise KeyError(f"no grader named {name!r}; known: {names()}")
    return importlib.import_module(f"harness.grader.graders.{name}.check")


def grade_program(name: str) -> Path:
    get(name)
    return GRADERS_DIR / name / "grade.py"
