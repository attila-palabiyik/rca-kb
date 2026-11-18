# RCA KB harness

Compares ways of giving a hardware-debugging agent a knowledge base. An
approach builds its KB while the agent works through one set of tasks (A).
The KB is then frozen and the agent is run on a second, disjoint set (B) with
it. Each approach is compared with the same agent run without a KB, on
correctness, tokens and time.

The design is in [docs/spec.md](docs/spec.md). Results are in
[docs/report.md](docs/report.md).

## Where things are

| What | Where |
|---|---|
| Implementation | [harness/](harness/), one package per component of the spec |
| Tasks | [datasets/chipbench/](datasets/chipbench/): 89 ChipBench debugging cases in the harness's task format, and the split |
| Grader | [harness/grader/graders/iverilog_mismatch/](harness/grader/graders/iverilog_mismatch/) |
| KB approaches | [configs/kb/](configs/kb/): one folder each, built from the shared pieces in `_pieces/` |
| Experiments | [configs/experiments/](configs/experiments/) |
| Results | [runs/](runs/): one folder per run with its record, answer, verdict, monitor report and assessment |
| Trajectories | `runs/*/*/*/*/trial/`, delivered as an archive beside the repository |
| Reports | [reports/](reports/), generated from `runs/` |
| Sources | [docs/spec.md](docs/spec.md), section 11 |

## Quick start

Needs Linux or WSL2, Docker, [uv](https://docs.astral.sh/uv/), Harbor 0.26.0
(`uv tool install harbor==0.26.0`) and `OPENAI_API_KEY` in the environment.

```bash
uv sync
docker build -t rcakb-agent:1 configs/image
```

Regenerate the report from the stored records, with no agent runs:

```bash
uv run python -m harness.cli report baseline --out reports/baseline
```

Run an experiment. Restarting skips whatever is already recorded:

```bash
uv run python -m harness.cli run configs/experiments/baseline.toml
uv run python -m harness.cli run configs/experiments/kb-notes.toml
```

Certify and describe its runs, then report against the baseline:

```bash
uv run python -m harness.cli monitor kb-notes
uv run python -m harness.cli assess kb-notes
uv run python -m harness.cli report baseline kb-notes --out reports/main
```

## Rebuilding from the source benchmark

```bash
git clone https://github.com/zhongkaiyu/ChipBench .cache/chipbench
git -C .cache/chipbench checkout b4ba3a06759804ec88c26c3cf15b28b9a90b3443
uv run python -m harness.cli convert chipbench --source .cache/chipbench --commit b4ba3a06759804ec88c26c3cf15b28b9a90b3443
uv run python -m harness.cli split chipbench --seed 1
uv run python -m harness.cli check-tasks chipbench
uv run python scripts/make_approaches.py
```

`check-tasks` runs every task twice with no model: a known-good answer must
pass and the untouched workspace must fail. A task that fails either is left
out of experiments.

## Tests

```bash
uv run pytest tests/fast                    # no container, network or model
uv run pytest tests/container -m container  # needs Docker and the image
```

## Versions

Pinned in [configs/image/Dockerfile](configs/image/Dockerfile),
[configs/base.toml](configs/base.toml) and `uv.lock`: Codex CLI 0.170.0,
Icarus Verilog 12.0, Node 22.23.5, Harbor 0.26.0.

## What is reused

- [ChipBench](https://github.com/zhongkaiyu/ChipBench), MIT licence: the
  prompts, reference modules and testbenches, unmodified.
- [Harbor](https://docs.harborframework.com), Apache-2.0: runs each task in
  a container and grades it in a second one.
- [Codex CLI](https://developers.openai.com/codex): the agent.
- [fastembed](https://github.com/qdrant/fastembed) with the
  `BAAI/bge-small-en-v1.5` model: similarity search inside the container.
