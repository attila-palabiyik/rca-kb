import json

import pytest

from harness.dataset.adapters.chipbench import extract_buggy_module
from harness.dataset.loader import DatasetError, Split, load_dataset, load_split, validate_split
from harness.dataset.split import draw_split, write_split


def test_loads_tasks_and_a_stable_version(dataset_dir):
    first, second = load_dataset(dataset_dir), load_dataset(dataset_dir)
    assert sorted(first.tasks) == ["x__m1", "x__m2", "x__m3", "y__m1"]
    assert first.version == second.version
    assert first.tasks["x__m1"].grader == "iverilog_mismatch"


def test_version_changes_with_content(dataset_dir):
    before = load_dataset(dataset_dir).version
    (dataset_dir / "tasks" / "x__m2" / "private" / "ref.sv").write_text("// changed\n")
    assert load_dataset(dataset_dir).version != before


def test_a_task_missing_a_part_is_an_error(dataset_dir):
    (dataset_dir / "tasks" / "x__m2" / "task.json").unlink()
    with pytest.raises(DatasetError, match="missing task.json"):
        load_dataset(dataset_dir)


def test_duplicate_ids_are_an_error(dataset_dir):
    clash = dataset_dir / "tasks" / "x__m2" / "task.json"
    clash.write_text(json.dumps({"id": "x__m1", "tags": {"module": "m2"}}))
    with pytest.raises(DatasetError, match="not unique"):
        load_dataset(dataset_dir)


def test_split_keeps_a_module_on_one_side(dataset_dir):
    dataset = load_dataset(dataset_dir)
    for seed in range(20):
        split = draw_split(dataset, seed)
        assert not {dataset.group_of(t) for t in split.a} & {dataset.group_of(t) for t in split.b}
        assert sorted(split.a + split.b) == sorted(dataset.tasks)


def test_split_is_reproducible_and_round_trips(dataset_dir):
    dataset = load_dataset(dataset_dir)
    split = draw_split(dataset, seed=7)
    assert draw_split(dataset, seed=7) == split
    write_split(dataset, split)
    assert load_split(dataset, "main").a == split.a


def test_split_with_an_unknown_task_or_a_shared_module_is_refused(dataset_dir):
    dataset = load_dataset(dataset_dir)
    with pytest.raises(DatasetError, match="unknown task"):
        validate_split(dataset, Split("bad", ["nope"], ["x__m2"]))
    with pytest.raises(DatasetError, match="share groups"):
        validate_split(dataset, Split("bad", ["x__m1"], ["y__m1"]))
    with pytest.raises(DatasetError, match="share tasks"):
        validate_split(dataset, Split("bad", ["x__m2"], ["x__m2"]))


def test_adapter_takes_the_block_after_the_bug_sentence():
    prompt = ("Spec.\n```\nmodule helper(); endmodule\n```\n\n"
              "the code below in TopModule has bug, please fix that:\n"
              "```\nmodule TopModule(input a);\nendmodule\n```\n")
    assert extract_buggy_module(prompt) == "module TopModule(input a);\nendmodule\n"
    assert extract_buggy_module("no marker here ```\nmodule TopModule(); endmodule\n```") is None
