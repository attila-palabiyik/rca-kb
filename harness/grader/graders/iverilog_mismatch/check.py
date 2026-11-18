"""Host side of the `iverilog_mismatch` grader. Executes nothing from a Submission."""

from __future__ import annotations

import json
import re
from pathlib import Path

from harness.dataset.loader import Task

GRADE_PROGRAM = Path(__file__).with_name("grade.py")
MODULE = re.compile(r"^[ \t]*module\s+([A-Za-z_][A-Za-z0-9_]*)\b.*?^[ \t]*endmodule\b[^\n]*\n?",
                    re.DOTALL | re.MULTILINE)


def _params(task: Task) -> dict:
    return json.loads((task.private / "params.json").read_text(encoding="utf-8"))


def submission_files(task: Task) -> list[str]:
    """The files that make up a Submission, relative to the workspace."""
    return list(_params(task)["submission_files"])


def check_task(task: Task) -> list[str]:
    """Problems that would stop this grader scoring the task; empty means acceptable."""
    problems = []
    for name in ("ref.sv", "test.sv", "params.json"):
        if not (task.private / name).is_file():
            problems.append(f"private/{name} is missing")
    if problems:
        return problems
    for name in submission_files(task):
        if not (task.workspace / name).is_file():
            problems.append(f"workspace/{name} is missing")
        if name not in task.instructions:
            problems.append(f"the instructions do not name {name}")
    if "Mismatches:" not in (task.private / "test.sv").read_text(encoding="utf-8"):
        problems.append("the testbench prints no result line")
    return problems


def _modules(source: str) -> dict[str, str]:
    return {m.group(1): m.group(0) for m in MODULE.finditer(source)}


def known_good(task: Task) -> dict[str, bytes]:
    """A Submission that must pass: the reference, renamed to the answer's module.

    Helper modules the workspace file defines, and the reference file does not,
    are carried over so that every module is defined exactly once at compile.
    """
    (answer_file,) = submission_files(task)
    reference = _modules((task.private / "ref.sv").read_text(encoding="utf-8"))
    workspace = _modules((task.workspace / answer_file).read_text(encoding="utf-8"))
    top = re.sub(r"\bRefModule\b", "TopModule", reference["RefModule"])
    helpers = [body for name, body in workspace.items() if name != "TopModule" and name not in reference]
    return {answer_file: "\n".join([top, *helpers]).encode("utf-8")}
