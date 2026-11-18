"""Tests that need Docker and the harness image. Run before every experiment:

    pytest tests/container -m container
"""

from __future__ import annotations

import json
import shutil
import subprocess
from pathlib import Path

import pytest

from harness.config.load import Condition, RunSpec, load_base, load_experiment
from harness.dataset.loader import load_dataset
from harness.grader import registry
from harness.records import store
from harness.report.render import build_report
from harness.runner.executor import HarborExecutor

from ..conftest import GOOD, REPO

pytestmark = pytest.mark.container
IMAGE = "rcakb-agent:1"


def grade_in_container(task, submission: dict[str, str], tmp_path: Path) -> dict:
    """Run the grade program the way a run does: in the image, on a Submission."""
    work = tmp_path / "grade"
    shutil.rmtree(work, ignore_errors=True)
    (work / "app").mkdir(parents=True)
    (work / "out").mkdir()
    shutil.copytree(task.private, work / "tests")
    shutil.copy2(registry.grade_program(task.grader), work / "tests" / "grade.py")
    for name, text in submission.items():
        (work / "app" / name).write_text(text)
    subprocess.run(["docker", "run", "--rm", "--network", "none", "-v", f"{work}:/work", IMAGE,
                    "python3", "/work/tests/grade.py", "/work/app", "/work/tests", "/work/out"],
                   check=True, capture_output=True)
    return json.loads((work / "out" / "verdict.json").read_text())


@pytest.fixture
def task(dataset_dir):
    return load_dataset(dataset_dir).tasks["x__m1"]


def test_a_correct_module_passes(task, tmp_path):
    verdict = grade_in_container(task, {"TopModule.sv": GOOD}, tmp_path)
    assert (verdict["result"], verdict["reason"]) == ("pass", "ok")
    assert verdict["details"] == {"mismatches": 0, "samples": 4}


@pytest.mark.parametrize("submission, reason", [
    ({"TopModule.sv": "module TopModule(input a, input b, output y);\n  assign y = a | b;\nendmodule\n"},
     "mismatch"),
    ({"TopModule.sv": "module TopModule(input a, input b, output y)\n  assign y = a & b\nendmodule\n"},
     "compile_error"),
    ({}, "missing_file"),
    ({"TopModule.sv": 'module TopModule(input a, input b, output y);\n  assign y = a & b;\n'
                      '  initial begin $display("Mismatches: 0 in 4 samples"); $finish; end\nendmodule\n'},
     "forbidden_construct"),
    ({"TopModule.sv": "module TopModule(input a, input b, output y);\n  assign y = good1.y;\nendmodule\n"},
     "forbidden_construct"),
])
def test_each_kind_of_wrong_answer_fails_for_the_right_reason(task, tmp_path, submission, reason):
    verdict = grade_in_container(task, submission, tmp_path)
    assert (verdict["result"], verdict["reason"]) == ("fail", reason)


def test_grading_twice_gives_the_same_verdict(task, tmp_path):
    first = grade_in_container(task, {"TopModule.sv": GOOD}, tmp_path)
    assert grade_in_container(task, {"TopModule.sv": GOOD}, tmp_path) == first


def test_from_experiment_file_to_report_with_the_builtin_agents(repo, tmp_path):
    """The known-good agent passes and the do-nothing agent fails on the same task,
    which shows that what is graded is what the agent left behind. No model is called."""
    (repo / "configs" / "experiments" / "e2e.toml").write_text(
        'dataset = "tiny"\nsplit = "main"\nrepeats = 1\n'
        '[[conditions]]\nname = "baseline"\nmode = "baseline"\nside = ["A", "B"]\n')
    experiment = load_experiment(repo / "configs" / "experiments" / "e2e.toml", repo)
    executor = HarborExecutor(experiment.dataset, tmp_path / "work")
    setup = load_base(repo / "configs")
    store.init_experiment(repo, experiment)

    tasks = sorted(experiment.dataset.tasks)[:2]
    outcomes = {}
    for index, (task_id, agent) in enumerate(zip(tasks, ("oracle", "nop"))):
        trial = executor.run_builtin(experiment.dataset.tasks[task_id], setup, agent)
        run = RunSpec(f"e2e/baseline/0/{task_id}", "e2e", Condition("baseline", "baseline", ("A", "B")),
                      task_id, 0, setup)
        store.write_run(repo, experiment, run, trial)
        outcomes[agent] = trial.verdict["result"]
    assert outcomes == {"oracle": "pass", "nop": "fail"}

    runs = store.load_runs(repo / "runs" / "e2e")
    assert sorted(r.verdict_result for r in runs) == ["fail", "pass"]
    assert all(r.result == "pending" for r in runs if r.verdict_result == "pass")   # not yet monitored
    report = build_report([repo / "runs" / "e2e"], REPO / "configs" / "prices.toml", tmp_path / "report")
    assert report["provisional"] is True
    counts = report["trust"]["run_counts"]["e2e/baseline"]
    assert counts["planned"] == len(experiment.dataset.tasks) and counts["recorded"] == 2
    assert (tmp_path / "report" / "report.md").is_file()
