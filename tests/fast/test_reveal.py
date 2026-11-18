"""Showing the agent the grading result before the Update turn."""

import pytest

from harness.config.load import ConfigError, apply_overlay, load_base, load_experiment
from harness.dataset.loader import load_dataset
from harness.runner.materialise import materialise_update, result_block

from .test_config import EXPERIMENT, write_experiment

REVEALED = (EXPERIMENT
            .replace('side = ["A"]\n[[conditions]]\nname     = "eval"',
                     'side = ["A"]\nreveal = "fix"\n[[conditions]]\nname     = "eval"')
            .replace('snapshot = "build"', 'snapshot = "build"\nreveal   = "fix"')
            .replace('snapshot = "seed"', 'snapshot = "seed"\nreveal   = "fix"'))


def task(repo):
    return load_dataset(repo / "datasets" / "tiny").tasks["x__m1"]


def test_the_result_shows_the_verdict_and_with_fix_the_correct_change(repo):
    failed = {"result": "fail", "reason": "mismatch", "details": {"mismatches": 2, "samples": 4}}
    verdict_only = result_block(task(repo), failed, "verdict")
    assert "FAILED: 2 of 4 samples" in verdict_only and "```diff" not in verdict_only
    with_fix = result_block(task(repo), failed, "fix")
    assert "-  assign y = a | b;" in with_fix and "+  assign y = a & b;" in with_fix
    passed = result_block(task(repo), {"result": "pass", "reason": "ok", "details": {"samples": 4}}, "verdict")
    assert "PASSED" in passed and "FAILED" not in passed


@pytest.mark.parametrize("reason, phrase", [
    ("compile_error", "did not compile"), ("missing_file", "was missing"),
    ("sim_timeout", "did not finish"), ("forbidden_construct", "may not use"),
])
def test_every_kind_of_failure_is_described(repo, reason, phrase):
    verdict = {"result": "fail", "reason": reason, "details": {}}
    assert phrase in result_block(task(repo), verdict, "verdict")
    assert "could not be graded" in result_block(task(repo), None, "verdict")


def test_the_reference_itself_is_never_shown_only_the_change(repo):
    shown = result_block(task(repo), {"result": "fail", "reason": "mismatch",
                                      "details": {"mismatches": 1, "samples": 4}}, "fix")
    assert "RefModule" not in shown and "tb" not in shown.split("```diff")[1].split()


def test_with_the_result_shown_the_skeletons_say_so(repo):
    base = load_base(repo / "configs")
    plain = apply_overlay(base, repo / "configs", "notes")
    shown = apply_overlay(base, repo / "configs", "notes", revealed=True)
    assert "never learned whether a fix passed" in plain.instructions
    assert "shown how its answer had been graded" in shown.instructions
    assert "You were not told" in plain.update_prompt and "The result is above" in shown.update_prompt
    assert plain.hash != shown.hash


def test_a_condition_reads_a_kb_only_with_the_setting_it_was_built_with(repo):
    experiment = load_experiment(write_experiment(repo, REVEALED), repo)
    assert {c.name: c.reveal for c in experiment.conditions} == {
        "baseline": "none", "build": "fix", "eval": "fix", "empty": "fix"}
    assert "shown how its answer" in experiment.setups["eval"].instructions
    mismatched = REVEALED.replace('snapshot = "build"\nreveal   = "fix"', 'snapshot = "build"')
    with pytest.raises(ConfigError, match="reveal differs"):
        load_experiment(write_experiment(repo, mismatched, "bad"), repo)
    with pytest.raises(ConfigError, match="reveal is one of"):
        load_experiment(write_experiment(repo, REVEALED.replace('reveal = "fix"', 'reveal = "all"'), "bad2"), repo)


def test_the_update_run_starts_from_the_agents_answer_and_grades_nothing(repo, tmp_path):
    setup = apply_overlay(load_base(repo / "configs"), repo / "configs", "notes", revealed=True)
    answer = tmp_path / "TopModule.sv"
    answer.write_text("// what the agent left\n")
    kb = tmp_path / "kb"
    kb.mkdir()
    built = materialise_update(task(repo), setup, tmp_path / "update", kb_copy=kb,
                               submission={"TopModule.sv": answer}, prompt="RESULT\n\nupdate", salt="run-1")
    workspace = built.task_dir / "environment" / "workspace" / "TopModule.sv"
    assert workspace.read_text() == "// what the agent left\n"
    assert (built.task_dir / "instruction.md").read_text().startswith("RESULT")
    assert not (built.task_dir / "tests" / "ref.sv").exists()
    assert built.mounts == [{"type": "bind", "source": str(kb), "target": "/kb"}]
    other = materialise_update(task(repo), setup, tmp_path / "other", kb_copy=kb,
                               submission={"TopModule.sv": answer}, prompt="x", salt="run-2")
    name = lambda b: [l for l in (b.task_dir / "task.toml").read_text().splitlines() if l.startswith("name")]
    assert name(built) != name(other)          # two runs never share a built image
