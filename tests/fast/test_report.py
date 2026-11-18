from collections import Counter

import pytest

from harness.report import compare
from harness.report.metrics import Loaded, Row, condition_metrics, cost, within_budget
from harness.report.render import ReportError, _check_comparable

PRICES = {"models": {"m": {"input": 2.0, "cache_write": 2.5, "cached_input": 0.1, "output": 10.0}}}


def row(task, passed, condition="baseline", repeat=0, tokens=1000, seconds=10.0, group=None,
        limitations=None, mode="baseline") -> Row:
    return Row(experiment=condition, condition=condition, mode=mode, kb=None, side="B", task_id=task,
               group=group or task, tags={"category": "x"}, repeat=repeat, position=None,
               status="completed", passed=passed, pending=False,
               usage={"input_uncached": tokens, "input_cached": 0, "output": 0, "responses": 3},
               seconds=seconds, update_usage={}, update_seconds=None, tools=Counter(), kb_changed=False,
               kb_used=None, limitations=limitations, monitor_status="certified", findings=[], review=None)


def test_cost_uses_each_price_once():
    usage = {"input_uncached": 1_000_000, "input_cache_write": 400_000, "input_cached": 2_000_000,
             "output": 100_000}
    assert cost(usage, PRICES, "m") == pytest.approx(0.6 * 2.0 + 0.4 * 2.5 + 2 * 0.1 + 0.1 * 10.0)


def test_the_task_is_the_unit_not_the_run():
    """One task passed three times is not three successes against one failure."""
    rows = [row("easy", True, repeat=r) for r in range(3)] + [row("hard", False)]
    metrics = condition_metrics(rows, PRICES, "m")
    assert metrics["pass_rate"] == pytest.approx(0.5)
    assert metrics["pass@3"] == pytest.approx(0.5) and metrics["pass^3"] == pytest.approx(0.5)
    assert metrics["tasks"] == 2 and metrics["runs"] == 4


def test_pass_at_k_and_pass_power_k_bracket_the_pass_rate():
    rows = [row("t", True, repeat=0), row("t", False, repeat=1), row("t", False, repeat=2)]
    metrics = condition_metrics(rows, PRICES, "m")
    assert metrics["pass@3"] == 1.0 and metrics["pass^3"] == 0.0
    assert metrics["pass_rate"] == pytest.approx(1 / 3)


def test_bootstrap_recovers_a_known_rate_and_keeps_groups_together():
    values = {f"t{i}": 1.0 if i < 30 else 0.0 for i in range(100)}
    alone = compare.bootstrap(values, {t: t for t in values})
    assert alone["value"] == pytest.approx(0.3)
    assert alone["low"] < 0.3 < alone["high"] and 0.03 < alone["se"] < 0.06   # sqrt(.3*.7/100) = .046
    # The same tasks in ten groups of identical outcomes carry far less information.
    grouped = compare.bootstrap(values, {t: f"g{int(t[1:]) // 10}" for t in values})
    assert grouped["se"] > 2 * alone["se"]
    assert compare.bootstrap(values, {t: t for t in values}) == alone          # seeded


def test_a_paired_comparison_with_a_known_answer():
    baseline = [row(f"t{i}", i < 4) for i in range(10)]
    better = [row(f"t{i}", i < 7, "kb", tokens=500, seconds=5.0, mode="eval") for i in range(10)]
    result = compare.paired(better, baseline, PRICES, "m")
    assert result["pass_rate_difference"]["value"] == pytest.approx(0.3)
    assert (result["helped"], result["harmed"], result["unchanged"]) == (3, 0, 7)
    assert result["token_ratio"]["value"] == pytest.approx(0.5)
    assert result["time_ratio"]["value"] == pytest.approx(0.5)
    same = compare.paired(baseline, baseline, PRICES, "m")
    assert same["pass_rate_difference"]["value"] == 0 and same["token_ratio"]["value"] == pytest.approx(1.0)


def test_gains_and_losses_are_not_netted():
    baseline = [row("a", True), row("b", False)]
    swapped = [row("a", False, "kb", mode="eval"), row("b", True, "kb", mode="eval")]
    result = compare.paired(swapped, baseline, PRICES, "m")
    assert result["pass_rate_difference"]["value"] == 0
    assert (result["helped"], result["harmed"]) == (1, 1)


def test_limitations_resolved_persisting_and_introduced():
    baseline = [row("a", False, limitations=frozenset({"slow", "wrong"})),
                row("b", False, limitations=frozenset({"slow"}))]
    with_kb = [row("a", True, "kb", limitations=frozenset({"wrong", "misled"}), mode="eval"),
               row("b", True, "kb", limitations=frozenset({"slow"}), mode="eval")]
    changes = compare.limitations(with_kb, baseline)
    assert changes["slow"] == {"resolved": 0.5, "persisting": 0.5, "introduced": 0.0}
    assert changes["wrong"] == {"resolved": 0.0, "persisting": 0.5, "introduced": 0.0}
    assert changes["misled"] == {"resolved": 0.0, "persisting": 0.0, "introduced": 0.5}


def test_a_failure_is_never_solved_within_any_budget():
    rows = [row("a", True, tokens=100), row("b", False, tokens=50)]
    assert max(point["solved"] for point in within_budget(rows)) == 0.5


def test_experiments_run_differently_are_not_compared():
    def loaded(**other):
        base = {"base_setup_hash": "h", "dataset_version": "v", "split": "main", "seed": 1}
        return Loaded([], {"baseline": base, "kb": {**base, **other}}, False, 0, {})

    _check_comparable(loaded())
    for key, value in (("base_setup_hash", "x"), ("dataset_version", "x"), ("split", "other"), ("seed", 2)):
        with pytest.raises(ReportError, match=key):
            _check_comparable(loaded(**{key: value}))
