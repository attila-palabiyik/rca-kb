import json
from pathlib import Path

import pytest

from harness.config.load import apply_overlay, load_base
from harness.dataset.loader import load_dataset
from harness.monitor.monitor import pattern_findings
from harness.records.store import Run
from harness.runner import kb as kbstate
from harness.runner.executor import turn_usage
from harness.runner.materialise import agent_config, materialise


def run_with(status="completed", verdict="pass", monitor=None, review=None) -> Run:
    return Run(Path("."), {"status": status, "phases": {}, "condition": {"name": "c", "mode": "baseline"},
                           "run_id": "r", "task_id": "t", "repeat": 0, "kb": {}},
               {"result": verdict} if verdict else None,
               {"status": monitor} if monitor else None, None,
               {"decision": review} if review else None)


@pytest.mark.parametrize("kwargs, expected", [
    (dict(monitor="certified"), "pass"),
    (dict(monitor="flagged", review="cleared"), "pass"),
    (dict(monitor="flagged"), "pending"),                    # flagged, awaiting review
    (dict(), "pending"),                                     # not yet monitored
    (dict(verdict="error"), "pending"),                      # awaiting re-grade
    (dict(verdict=None), "pending"),
    (dict(verdict="fail", monitor="certified"), "fail"),
    (dict(status="timeout", verdict="pass", monitor="certified"), "fail"),
    (dict(status="error", verdict=None), "fail"),            # retries exhausted
    (dict(monitor="certified", review="void"), "fail"),      # voided on review
    (dict(monitor="flagged", review="void"), "fail"),
])
def test_the_one_result_rule(kwargs, expected):
    assert run_with(**kwargs).result == expected


def test_no_kind_of_run_is_without_a_result():
    for status in ("completed", "timeout", "error"):
        for verdict in ("pass", "fail", "error", None):
            assert run_with(status=status, verdict=verdict).result in ("pass", "fail", "pending")


def step(source, prompt=0, cached=0, completion=0, written=0):
    metrics = {"prompt_tokens": prompt, "cached_tokens": cached, "completion_tokens": completion,
               "extra": {"cache_write_input_tokens": written}}
    return {"source": source, **({"metrics": metrics} if source == "agent" else {})}


def test_a_turn_is_charged_only_for_what_follows_its_own_prompt(tmp_path):
    """Cached tokens are not counted twice, and an earlier turn is not counted at all."""
    earlier = [step("user"), step("agent", 1000, 800, 50), step("agent", 1200, 1000, 60)]
    this_turn = [step("user"), step("agent", 2000, 1500, 100, 400), step("agent", 2500, 2400, 20, 80)]
    file = tmp_path / "trajectory.json"
    file.write_text(json.dumps({"steps": earlier + this_turn}))
    assert turn_usage(None, file) == {"input_uncached": 600, "input_cached": 3900,
                                      "input_cache_write": 480, "output": 120, "responses": 2}
    file.write_text(json.dumps({"steps": earlier}))
    assert turn_usage(None, file)["input_uncached"] == 400


def test_kb_state_is_identified_by_content_and_restored_exactly(tmp_path):
    state = tmp_path / "kb"
    (state / "entries").mkdir(parents=True)
    (state / "entries" / "001.md").write_text("a lesson")
    snapshots = tmp_path / "snapshots"
    first = kbstate.snapshot(state, snapshots)
    assert kbstate.snapshot(state, snapshots) == first                 # same content, same ID
    copy = kbstate.restore(snapshots, first, tmp_path / "copy")
    (copy / "entries" / "002.md").write_text("written by a frozen run")
    assert kbstate.identify(snapshots / first) == first                # the snapshot did not change
    assert kbstate.snapshot(copy, snapshots) != first
    assert kbstate.identify(None) == kbstate.identify(tmp_path / "missing")


def test_grading_assets_never_enter_the_agents_container(repo, tmp_path):
    task = load_dataset(repo / "datasets" / "tiny").tasks["x__m1"]
    base = load_base(repo / "configs")
    built = materialise(task, base, tmp_path / "task")
    in_agent_image = {p.name for p in (built.task_dir / "environment").rglob("*") if p.is_file()}
    assert in_agent_image == {"Dockerfile", "TopModule.sv"}
    assert (built.task_dir / "tests" / "ref.sv").is_file()             # only the grading container has it
    assert "ref.sv" not in (built.task_dir / "environment" / "Dockerfile").read_text()
    assert built.mounts == [] and built.steps == ["solve"]
    assert agent_config(base)["features"]["memories"] is False


def test_a_baseline_run_has_no_kb_and_a_kb_run_gets_one_mount(repo, tmp_path):
    task = load_dataset(repo / "datasets" / "tiny").tasks["x__m1"]
    base = load_base(repo / "configs")
    notes = apply_overlay(base, repo / "configs", "notes")
    kb_copy = tmp_path / "kb"
    kb_copy.mkdir()
    built = materialise(task, notes, tmp_path / "task", kb_copy=kb_copy, with_update=True)
    assert built.mounts == [{"type": "bind", "source": str(kb_copy), "target": "/kb"}]
    assert built.steps == ["solve", "update"]
    update = (built.task_dir / "steps" / "update" / "instruction.md").read_text()
    assert "update the knowledge base" in update
    assert not (built.task_dir / "steps" / "update" / "tests" / "ref.sv").exists()
    solve = (built.task_dir / "steps" / "solve" / "instruction.md").read_text()
    baseline = (materialise(task, base, tmp_path / "plain").task_dir / "instruction.md").read_text()
    assert solve.startswith(baseline.rstrip("\n")) and "/kb" not in baseline


def test_the_pattern_match_flags_grading_assets_and_network_use_only():
    def trajectory(command):
        return {"steps": [{"tool_calls": [{"function_name": "exec_command", "arguments": {"cmd": command}}]}]}

    assert pattern_findings({"solve": trajectory("iverilog -o sim /app/tests/tb.sv TopModule.sv")}) == []
    assert pattern_findings({"solve": trajectory("cat /tests/ref.sv")})[0]["category"] == "outside_answer"
    assert pattern_findings({"solve": trajectory("curl https://example.com/answer")})[0]["category"] == "rule_violation"
