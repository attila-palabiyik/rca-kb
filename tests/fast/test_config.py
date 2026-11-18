import pytest

from harness.config.load import ConfigError, apply_overlay, chain_order, load_base, load_experiment

EXPERIMENT = """
dataset = "tiny"
split   = "main"
repeats = 2
seed    = 1
[[conditions]]
name = "baseline"
mode = "baseline"
side = ["A", "B"]
[[conditions]]
name = "build"
mode = "build"
kb   = "notes"
side = ["A"]
[[conditions]]
name     = "eval"
mode     = "eval"
kb       = "notes"
side     = ["B"]
snapshot = "build"
[[conditions]]
name     = "empty"
mode     = "eval"
kb       = "notes"
side     = ["B"]
snapshot = "seed"
"""


def write_experiment(repo, text=EXPERIMENT, name="exp"):
    path = repo / "configs" / "experiments" / f"{name}.toml"
    path.write_text(text)
    return path


def test_a_kb_setup_differs_from_the_base_by_exactly_its_overlay(repo):
    base = load_base(repo / "configs")
    with_kb = apply_overlay(base, repo / "configs", "notes")
    for protected in ("agent", "model", "effort", "image", "limits", "network", "rules"):
        assert getattr(with_kb, protected) == getattr(base, protected)
    assert base.instructions == "" and base.update_prompt == "" and base.kb == {}
    assert with_kb.instructions and with_kb.update_prompt and with_kb.kb["path"] == "/kb"
    assert with_kb.settings == base.settings and with_kb.agent_memory == base.agent_memory
    assert with_kb.hash != base.hash


def test_the_base_setup_has_the_cli_memory_off_and_web_search_disabled(repo):
    base = load_base(repo / "configs")
    assert base.agent_memory == {"builtin": "off", "session": "fresh"}
    assert base.settings["web_search"] == "disabled"
    assert base.settings["features"]["memories"] is False


def test_first_turn_is_rules_then_task_then_instructions(repo):
    setup = apply_overlay(load_base(repo / "configs"), repo / "configs", "notes")
    text = setup.first_turn("THE TASK")
    assert text.index("Work only inside") < text.index("THE TASK") < text.index("Knowledge base")


@pytest.mark.parametrize("line, message", [
    ('model = "other"', "may not change 'model'"),
    ('rules = "x.md"', "may not change 'rules'"),
    ("[settings]\nweb_search = \"live\"", "overrides base settings"),
    ("surprise = 1", "unknown overlay key"),
    ("[agent_memory]\nsession = \"sometimes\"", "is not valid"),
])
def test_an_overlay_cannot_change_what_is_protected(repo, line, message):
    folder = repo / "configs" / "kb" / "bad"
    folder.mkdir()
    (folder / "overlay.toml").write_text(line + "\n")
    with pytest.raises(ConfigError, match=message):
        apply_overlay(load_base(repo / "configs"), repo / "configs", "bad")


def test_chain_order_depends_on_seed_and_chain_only():
    tasks = [f"t{i}" for i in range(10)]
    assert chain_order(tasks, 1, 0) == chain_order(list(reversed(tasks)), 1, 0)
    assert chain_order(tasks, 1, 0) != chain_order(tasks, 1, 1)
    assert chain_order(tasks, 1, 0) != chain_order(tasks, 2, 0)


def test_an_experiment_expands_into_batches_and_chains(repo):
    experiment = load_experiment(write_experiment(repo), repo)
    a, b = len(experiment.split.a), len(experiment.split.b)
    sizes = {batch[0].condition.name: len(batch) for batch in experiment.batches}
    assert sizes == {"baseline": 2 * (a + b), "eval": 2 * b, "empty": 2 * b}
    assert len(experiment.chains) == 2 and all(len(chain) == a for chain in experiment.chains)
    assert [run.position for run in experiment.chains[0]] == list(range(a))
    assert experiment.chains[0][0].run_id.startswith("exp/build/0/")


def test_every_approach_gets_the_same_task_order(repo):
    first = load_experiment(write_experiment(repo), repo)
    other = load_experiment(write_experiment(repo, EXPERIMENT.replace('"notes"', '"summaries"'), "other"), repo)
    for mine, theirs in zip(first.chains, other.chains):
        assert [r.task_id for r in mine] == [r.task_id for r in theirs]


@pytest.mark.parametrize("change, message", [
    (("dataset", "surprise = 1\ndataset"), "unknown key"),
    (('snapshot = "build"', 'snapshot = "elsewhere"'), "neither 'seed' nor a build condition"),
    (('kb   = "notes"\nside = ["A"]', 'kb   = "no-such"\nside = ["A"]'), "no KB approach named"),
    (('mode = "baseline"', 'mode = "sideways"'), "unknown mode"),
])
def test_a_bad_experiment_file_is_refused(repo, change, message):
    old, new = change
    with pytest.raises(ConfigError, match=message):
        load_experiment(write_experiment(repo, EXPERIMENT.replace(old, new, 1)), repo)


def test_a_task_that_failed_its_checks_is_left_out(repo):
    (repo / "datasets" / "tiny" / "checks.json").write_text('{"x__m2": {"ok": false}}')
    experiment = load_experiment(write_experiment(repo), repo)
    assert all(run.task_id != "x__m2" for batch in experiment.batches for run in batch)
    assert experiment.resolved["excluded_tasks"] == ["x__m2"]
