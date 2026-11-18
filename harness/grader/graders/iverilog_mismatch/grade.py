#!/usr/bin/env python3
"""Grades one Submission inside the grading container.

Compiles the Submission with the task's reference module and testbench,
simulates, and passes on zero mismatches. Standalone on purpose: it runs in a
container that has Icarus Verilog and Python but not the harness.

Usage: grade.py <submission_dir> <private_dir> <out_dir>
Writes <out_dir>/verdict.json and <out_dir>/reward.txt.
"""

from __future__ import annotations

import json
import re
import subprocess
import sys
import tempfile
from pathlib import Path

NAME = "iverilog_mismatch"
VERSION = "1"

RESULT_LINE = re.compile(r"^Mismatches: (\d+) in (\d+) samples\s*$", re.MULTILINE)
# System functions a design may use. Any other $name is a system task.
ALLOWED_SYSTEM = {"$clog2", "$signed", "$unsigned", "$bits"}
SYSTEM_NAME = re.compile(r"\$[A-Za-z_][A-Za-z0-9_$]*")
FORCE_OR_RELEASE = re.compile(r"\b(force|release)\b")
# A dotted reference into the testbench or the reference module.
HIERARCHICAL = re.compile(r"(\$root|\b(tb|good1|stim1|stats1|top_module1|RefModule))\s*\.")
COMMENT = re.compile(r"//[^\n]*|/\*.*?\*/", re.DOTALL)
STRING = re.compile(r'"(?:\\.|[^"\\])*"')


def forbidden_construct(source: str) -> str | None:
    """Why a Submission reaches outside its own module, or None if it does not."""
    code = STRING.sub('""', COMMENT.sub(" ", source))
    for name in SYSTEM_NAME.findall(code):
        if name not in ALLOWED_SYSTEM:
            return f"system task {name}"
    if match := FORCE_OR_RELEASE.search(code):
        return f"'{match.group(1)}' statement"
    if match := HIERARCHICAL.search(code):
        return f"hierarchical reference '{match.group(0).strip()}'"
    if re.search(r"`include\b", code):
        return "`include directive"
    return None


def _tool_version() -> str:
    try:
        out = subprocess.run(["iverilog", "-V"], capture_output=True, text=True, timeout=20).stdout
        return out.splitlines()[0].strip() if out else "unknown"
    except Exception:  # noqa: BLE001 - version is informational only
        return "unknown"


def grade(submission_dir: Path, private_dir: Path) -> dict:
    params = json.loads((private_dir / "params.json").read_text())
    files = [submission_dir / name for name in params["submission_files"]]
    verdict = {"result": "fail", "reason": "", "details": {}, "log": "",
               "grader": {"name": NAME, "version": VERSION, "iverilog": _tool_version()}}

    def done(result: str, reason: str, log: str = "", **details) -> dict:
        verdict.update(result=result, reason=reason, log=log, details=details)
        return verdict

    missing = [f.name for f in files if not f.is_file()]
    if missing:
        return done("fail", "missing_file", missing=missing)
    for f in files:
        if why := forbidden_construct(f.read_text(errors="replace")):
            return done("fail", "forbidden_construct", construct=why, file=f.name)

    with tempfile.TemporaryDirectory() as tmp:
        sim = Path(tmp) / "sim"
        compile_cmd = ["iverilog", "-g2012", "-o", str(sim),
                       str(private_dir / "test.sv"), str(private_dir / "ref.sv"), *map(str, files)]
        try:
            compiled = subprocess.run(compile_cmd, capture_output=True, text=True,
                                      timeout=params.get("compile_timeout_sec", 60))
        except subprocess.TimeoutExpired:
            return done("fail", "compile_error", "compile timed out")
        except OSError as exc:
            return done("error", "grader_error", f"could not run iverilog: {exc}")
        log = compiled.stdout + compiled.stderr
        if compiled.returncode != 0:
            return done("fail", "compile_error", log)
        try:
            ran = subprocess.run(["vvp", "-n", str(sim)], capture_output=True, text=True, cwd=tmp,
                                 timeout=params.get("sim_timeout_sec", 60))
        except subprocess.TimeoutExpired:
            return done("fail", "sim_timeout", log)
        except OSError as exc:
            return done("error", "grader_error", f"could not run vvp: {exc}")
        log += ran.stdout + ran.stderr

    results = RESULT_LINE.findall(log)
    if len(results) != 1:
        # The testbench prints exactly one result line. None or several means
        # the output cannot be trusted as the testbench's own.
        return done("fail", "mismatch", log, result_lines=len(results))
    mismatches, samples = map(int, results[0])
    if mismatches == 0 and samples > 0:
        return done("pass", "ok", log, mismatches=mismatches, samples=samples)
    return done("fail", "mismatch", log, mismatches=mismatches, samples=samples)


def main(argv: list[str]) -> int:
    submission_dir, private_dir, out_dir = map(Path, argv[1:4])
    out_dir.mkdir(parents=True, exist_ok=True)
    try:
        verdict = grade(submission_dir, private_dir)
    except Exception as exc:  # noqa: BLE001 - any grader fault is reported, not raised
        verdict = {"result": "error", "reason": "grader_error", "details": {}, "log": repr(exc),
                   "grader": {"name": NAME, "version": VERSION}}
    (out_dir / "verdict.json").write_text(json.dumps(verdict, indent=2) + "\n")
    (out_dir / "reward.txt").write_text("1\n" if verdict["result"] == "pass" else "0\n")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
