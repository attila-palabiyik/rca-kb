"""Shared fixtures: a small made-up dataset and a repository root to load config from."""

from __future__ import annotations

import json
import shutil
from pathlib import Path

import pytest

REPO = Path(__file__).resolve().parents[1]

GOOD = "module TopModule(input a, input b, output y);\n  assign y = a & b;\nendmodule\n"
BUGGY = "module TopModule(input a, input b, output y);\n  assign y = a | b;\nendmodule\n"
REFERENCE = "module RefModule(input a, input b, output y);\n  assign y = a & b;\nendmodule\n"
TESTBENCH = """`timescale 1ps/1ps
module tb();
  reg a, b; wire y_ref, y_dut; integer errors = 0, samples = 0, i;
  RefModule good1(.a(a), .b(b), .y(y_ref));
  TopModule top_module1(.a(a), .b(b), .y(y_dut));
  initial begin
    for (i = 0; i < 4; i = i + 1) begin
      {a, b} = i[1:0]; #1; samples = samples + 1;
      if (y_ref !== y_dut) errors = errors + 1;
    end
    $display("Mismatches: %1d in %1d samples", errors, samples);
    $finish;
  end
endmodule
"""


def write_task(root: Path, task_id: str, module: str, category: str = "logic") -> None:
    task = root / "tasks" / task_id
    (task / "public" / "workspace").mkdir(parents=True)
    (task / "private").mkdir()
    (task / "public" / "instructions.md").write_text("Fix the bug in `TopModule.sv`.\n")
    (task / "public" / "workspace" / "TopModule.sv").write_text(BUGGY)
    (task / "private" / "ref.sv").write_text(REFERENCE)
    (task / "private" / "test.sv").write_text(TESTBENCH)
    (task / "private" / "params.json").write_text(json.dumps(
        {"submission_files": ["TopModule.sv"], "compile_timeout_sec": 30, "sim_timeout_sec": 30}))
    (task / "task.json").write_text(json.dumps(
        {"id": task_id, "tags": {"category": category, "module": module}}))


@pytest.fixture
def dataset_dir(tmp_path: Path) -> Path:
    """Four tasks in three modules: m1 has two, m2 and m3 one each."""
    root = tmp_path / "datasets" / "tiny"
    for task_id, module in (("x__m1", "m1"), ("y__m1", "m1"), ("x__m2", "m2"), ("x__m3", "m3")):
        write_task(root, task_id, module, task_id.split("__")[0])
    (root / "dataset.json").write_text(json.dumps(
        {"name": "tiny", "grader": "iverilog_mismatch", "group_tag": "module"}))
    return root


@pytest.fixture
def repo(tmp_path: Path, dataset_dir: Path) -> Path:
    """A repository root with the real configs and the made-up dataset, split by module."""
    from harness.dataset.loader import load_dataset
    from harness.dataset.split import draw_split, write_split

    shutil.copytree(REPO / "configs", tmp_path / "configs")
    dataset = load_dataset(dataset_dir)
    write_split(dataset, draw_split(dataset, seed=1))
    return tmp_path
