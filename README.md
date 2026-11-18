# Knowledge bases for an RTL debugging agent

A comparison of thirteen ways for a debugging agent to store, organise and
retrieve what earlier runs learned. Each approach builds a knowledge base
(KB) while Codex CLI works through one set of ChipBench Verilog debugging
tasks (set A, 45 tasks in 17 modules). The KB is then frozen and the agent
is run with it on a second set (set B, 41 tasks in 15 other modules). Each
approach is compared with the same agent run without a KB, on correctness,
tokens and time to solution.

- **Slides:** [docs/slides.pdf](docs/slides.pdf), [docs/slides.pptx](docs/slides.pptx) (source [docs/slides.html](docs/slides.html))
- **Design:** [docs/spec.md](docs/spec.md)

## The brief, and where each part is answered

| The brief asks for | Where |
|---|---|
| Task 1: tasks from a hardware debugging benchmark, a set A and a disjoint set B, deterministic grading | [datasets/chipbench/](datasets/chipbench/): 89 ChipBench cases in the harness's task format; the split in `splits/main.json`; the grader in [harness/grader/graders/iverilog_mismatch/](harness/grader/graders/iverilog_mismatch/). Report, section 1. |
| Task 2: Codex headless, default settings, no KB; trajectories and results saved | [configs/experiments/baseline.toml](configs/experiments/baseline.toml); results in [runs/baseline/](runs/baseline/); trajectories in [archives/](archives/). The four settings that are not Codex's defaults are listed in the report, section 1, and in [configs/base.toml](configs/base.toml). |
| Task 3: analyse trajectories; explore ways to store and retrieve knowledge; implement at least one | Report, sections 2 and 3. All 51 approaches are defined in [configs/kb/](configs/kb/), assembled from the shared pieces in `configs/kb/_pieces/`; thirteen were run. |
| Task 4: per approach, run A with a mutable KB, freeze, run B, compare with the baseline on correctness, tokens and time; what worked, what failed, how A affects B | [configs/experiments/kb-*.toml](configs/experiments/); results in `runs/kb-*/`; report, sections 4 and 5. |
| Set B equal to set A, as a separate experiment | Not run. Report, section 6. |
| Bonus A, own benchmark; Bonus B, novel interfaces | Not attempted. |
| Implementation, tasks and graders, trajectories, results, report, cited resources | This repository, with trajectories in [archives/](archives/); references in the report and in [docs/spec.md](docs/spec.md), section 11. |

## Where things are

| What | Where |
|---|---|
| Implementation | [harness/](harness/), one package per component of the spec |
| Tasks | [datasets/chipbench/](datasets/chipbench/) |
| Grader | [harness/grader/graders/iverilog_mismatch/](harness/grader/graders/iverilog_mismatch/) |
| KB approaches | [configs/kb/](configs/kb/): one folder each. Report, appendix A, maps names to folders. |
| Experiments | [configs/experiments/](configs/experiments/) |
| Results | [runs/](runs/): one folder per run with its record, answer, verdict, monitor report and assessment; each built KB, with a snapshot after every task, under `runs/kb-*/kb/` |
| Trajectories | [archives/](archives/): one `<experiment>-trials.tar.gz` per experiment, holding every run's agent logs and trajectory, and for the two transcript approaches the session files their KB kept. Each unpacks into `runs/` in place; its checksum is in `runs/<experiment>/trials.sha256`. |
| Generated reports | [reports/](reports/), from `runs/` |

## Quick start

Needs Linux or WSL2, Docker, [uv](https://docs.astral.sh/uv/), Harbor 0.26.0
(`uv tool install harbor==0.26.0`) and `OPENAI_API_KEY` in the environment.

```bash
uv sync
docker build -t rcakb-agent:1 configs/image
```

Regenerate the tables and figures from the stored runs, with no agent runs,
and print the slides. The second command needs Chrome or Edge, and a network
connection for the typefaces, which come from Google Fonts:

```bash
uv run python -m harness.cli report baseline kb-shared-session kb-raw-cases kb-summaries kb-notes kb-note-similarity kb-playbook kb-rule-tags kb-wiki kb-skills kb-hierarchical-skills kb-guide-single-file kb-signature-guides kb-troubleshooting-tree --out reports/main
uv run python scripts/build_report_pdf.py
```

Run an experiment. Restarting skips whatever is already recorded. With
`gpt-6.2-sol` at medium effort a run costs about $0.06, so the baseline
(258 runs) costs about $16. What each KB approach cost is in the report,
Table B3 and Table B1:

```bash
uv run python -m harness.cli run configs/experiments/baseline.toml
uv run python -m harness.cli run configs/experiments/kb-notes.toml
```

Check and describe its runs, then report it against the baseline:

```bash
uv run python -m harness.cli monitor kb-notes
uv run python -m harness.cli assess kb-notes
uv run python -m harness.cli report baseline kb-notes --out reports/notes
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
out of experiments. Three are.

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
