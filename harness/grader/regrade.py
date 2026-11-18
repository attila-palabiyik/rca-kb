"""Grades a stored Submission again, without running an agent.

The grade program runs the way it does in a run: inside the harness image,
with no network, on the Submission and the task's private data.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import tempfile
from pathlib import Path

from harness.dataset.loader import Task

from . import registry


def regrade(task: Task, submission_dir: Path, image: str) -> dict:
    """The Verdict for the files in `submission_dir`."""
    with tempfile.TemporaryDirectory(prefix="regrade-") as tmp:
        work = Path(tmp)
        (work / "out").mkdir()
        shutil.copytree(submission_dir, work / "app") if submission_dir.is_dir() else (work / "app").mkdir()
        shutil.copytree(task.private, work / "tests")
        shutil.copy2(registry.grade_program(task.grader), work / "tests" / "grade.py")
        work.chmod(0o755)
        completed = subprocess.run(
            ["docker", "run", "--rm", "--network", "none", "-v", f"{work}:/work", image,
             "python3", "/work/tests/grade.py", "/work/app", "/work/tests", "/work/out"],
            capture_output=True, text=True)
        verdict_file = work / "out" / "verdict.json"
        if completed.returncode != 0 or not verdict_file.is_file():
            return {"result": "error", "reason": "grader_error", "details": {},
                    "log": completed.stderr[-2000:], "grader": {"name": task.grader}}
        verdict = json.loads(verdict_file.read_text())
        # Files the container wrote belong to root; hand them back before the folder is removed.
        subprocess.run(["docker", "run", "--rm", "-v", f"{work}:/work", image, "chmod", "-R", "a+rwX",
                        "/work"], capture_output=True)
        return verdict


def same_verdict(first: dict | None, second: dict | None) -> bool:
    """Whether two Verdicts agree on everything that is the grader's judgement."""
    if first is None or second is None:
        return first is second
    return all(first.get(key) == second.get(key) for key in ("result", "reason", "details"))
