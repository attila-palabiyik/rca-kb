"""Converts ChipBench's Verilog debugging cases into the harness's task format.

The only ChipBench-specific code in the harness. Each case is three files:
a prompt with the buggy module embedded in it, a reference module and a
testbench. The prompt is kept as the task's instructions; the buggy module is
also written to a workspace file, which the agent edits in place.
"""

from __future__ import annotations

import json
import re
import shutil
from pathlib import Path

SOURCE_REPO = "https://github.com/zhongkaiyu/ChipBench"
FOLDER_PREFIX = "dataset_debug_zero_shot_"
ANSWER_FILE = "TopModule.sv"
BUG_MARKER = "has bug"
FENCED = re.compile(r"```[^\n]*\n(.*?)```", re.DOTALL)
WHERE_THE_ANSWER_GOES = (
    f"\n\nThe module is in `{ANSWER_FILE}` in your working directory. "
    "Fix it in that file; it is your answer.\n"
)


def extract_buggy_module(prompt: str) -> str | None:
    """The fenced block that follows the 'has bug' sentence, if it defines TopModule."""
    marker = prompt.rfind(BUG_MARKER)
    if marker < 0:
        return None
    match = FENCED.search(prompt, marker)
    if not match or not re.search(r"\bmodule\s+TopModule\b", match.group(1)):
        return None
    return match.group(1).strip("\n") + "\n"


def convert(source: str | Path, out: str | Path, commit: str) -> list[str]:
    """Write the dataset to `out`. Returns the cases that were left out, with why."""
    source, out = Path(source), Path(out)
    tasks_dir = out / "tasks"
    if tasks_dir.exists():
        shutil.rmtree(tasks_dir)
    tasks_dir.mkdir(parents=True)
    skipped: list[str] = []

    for folder in sorted((source / "Verilog Debugging").glob(f"{FOLDER_PREFIX}*")):
        category = folder.name.removeprefix(FOLDER_PREFIX)
        for prompt_file in sorted(folder.glob("*_prompt.txt")):
            problem = prompt_file.name.removesuffix("_prompt.txt")
            task_id = f"{category}__{problem}"
            ref, test = folder / f"{problem}_ref.sv", folder / f"{problem}_test.sv"
            prompt = prompt_file.read_text(encoding="utf-8")
            module = extract_buggy_module(prompt)
            if module is None:
                skipped.append(f"{task_id}: buggy module could not be extracted")
                continue
            if not ref.exists() or not test.exists():
                skipped.append(f"{task_id}: reference or testbench missing")
                continue

            root = tasks_dir / task_id
            (root / "public" / "workspace").mkdir(parents=True)
            (root / "private").mkdir()
            _write(root / "public" / "instructions.md", prompt.rstrip("\n") + WHERE_THE_ANSWER_GOES)
            _write(root / "public" / "workspace" / ANSWER_FILE, module)
            _write(root / "private" / "ref.sv", ref.read_text(encoding="utf-8"))
            _write(root / "private" / "test.sv", test.read_text(encoding="utf-8"))
            _write_json(
                root / "private" / "params.json",
                {"submission_files": [ANSWER_FILE], "compile_timeout_sec": 60, "sim_timeout_sec": 60},
            )
            _write_json(
                root / "task.json",
                {"id": task_id, "tags": {"source": "chipbench", "category": category, "module": problem}},
            )

    _write_json(
        out / "dataset.json",
        {
            "name": "chipbench",
            "grader": "iverilog_mismatch",
            "group_tag": "module",
            "source_repo": SOURCE_REPO,
            "source_commit": commit,
            "source_path": "Verilog Debugging/dataset_debug_zero_shot_*",
            "licence": "MIT",
            "citation": f"ChipBench, {SOURCE_REPO}",
        },
    )
    return skipped


def _write(path: Path, text: str) -> None:
    path.write_text(text.replace("\r\n", "\n"), encoding="utf-8", newline="\n")


def _write_json(path: Path, data: dict) -> None:
    _write(path, json.dumps(data, indent=2) + "\n")
