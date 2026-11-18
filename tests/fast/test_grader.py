from harness.dataset.loader import load_dataset
from harness.grader import registry
from harness.grader.graders.iverilog_mismatch import check
from harness.grader.graders.iverilog_mismatch.grade import RESULT_LINE, forbidden_construct


def test_design_code_is_not_a_forbidden_construct():
    source = "module TopModule #(parameter W = $clog2(8)) (input signed [W-1:0] a);\n" \
             "  wire [W-1:0] b = $signed(a) + $unsigned(a); // $display in a comment\nendmodule\n"
    assert forbidden_construct(source) is None


def test_reaching_outside_the_module_is_forbidden():
    assert "system task" in forbidden_construct('initial $display("Mismatches: 0 in 9 samples");')
    assert "system task" in forbidden_construct("initial $finish;")
    assert "force" in forbidden_construct("initial force tb.clk = 0;")
    assert "hierarchical" in forbidden_construct("assign y = good1.y;")
    assert "include" in forbidden_construct('`include "/tests/ref.sv"')


def test_only_the_exact_result_line_counts():
    assert RESULT_LINE.findall("Mismatches: 0 in 455 samples\n") == [("0", "455")]
    assert RESULT_LINE.findall("Hint: Mismatches: 0 in 455 samples\n") == []
    assert len(RESULT_LINE.findall("Mismatches: 0 in 4 samples\nMismatches: 2 in 4 samples\n")) == 2


def test_registry_knows_the_grader_and_rejects_others():
    assert "iverilog_mismatch" in registry.names()
    assert registry.grade_program("iverilog_mismatch").name == "grade.py"
    try:
        registry.get("no_such_grader")
    except KeyError:
        return
    raise AssertionError("an unknown grader was accepted")


def test_task_check_and_submission_files(dataset_dir):
    task = load_dataset(dataset_dir).tasks["x__m1"]
    assert check.check_task(task) == []
    assert check.submission_files(task) == ["TopModule.sv"]
    (task.private / "ref.sv").unlink()
    assert check.check_task(task) == ["private/ref.sv is missing"]


def test_known_good_is_the_reference_renamed_with_missing_helpers_added(dataset_dir):
    task = load_dataset(dataset_dir).tasks["x__m1"]
    answer = check.known_good(task)["TopModule.sv"].decode()
    assert "module TopModule" in answer and "RefModule" not in answer and "a & b" in answer

    helper = "module helper(input a, output y);\n  assign y = a;\nendmodule\n"
    (task.workspace / "TopModule.sv").write_text((task.workspace / "TopModule.sv").read_text() + helper)
    assert check.known_good(task)["TopModule.sv"].decode().count("module helper") == 1
    (task.private / "ref.sv").write_text((task.private / "ref.sv").read_text() + helper)
    assert "module helper" not in check.known_good(task)["TopModule.sv"].decode()
