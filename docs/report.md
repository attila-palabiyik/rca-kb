# Report

Every table below is refreshed from the stored runs by

```bash
uv run python -m harness.cli report baseline --out reports/baseline --write-up docs/report.md
```

No number in this document is typed by hand.

## 1. Summary

_To be written once the approaches have been run._

## 2. What was evaluated

A KB approach is the thing under test. The agent (Codex CLI 0.170.0), the
model (`gpt-6.2-sol`) and the reasoning effort (medium) are held fixed, and a
run with a KB differs from a run without one by exactly the approach's
overlay.

- **Benchmark.** ChipBench's Verilog debugging cases: a specification, a
  module with one injected bug, and a hidden testbench that compares the
  answer with a reference on every sample. An answer passes on zero
  mismatches.
- **Split.** By module, so that no module has tasks on both sides. Tasks of a
  module share one correct file, and a module on both sides would put B's
  answers in a KB built on A.
- **Isolation.** Each run gets a fresh container. The testbench and the
  reference exist only in a second container, where the answer is graded
  after the agent has finished.
- **Floor and ceiling.** Before any agent ran, every task was run twice with
  no model: a known-good answer has to pass and the untouched workspace has
  to fail. Tasks that fail either check are left out; see section 7.

## 3. Baseline

<!-- generated: Conditions -->
| Condition | Side | Tasks | Runs | Pass rate (95%) | pass@k | pass^k | Tokens per run: uncached / cached / output | Cost per run | Cost per solved task | Time to solution | Responses | KB use |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| baseline | A | 45 | 135 | 69.6% (45.7 to 90.8) | 71.1% | 68.9% | 15455 / 52800 / 1736 | $0.061 | $0.088 | 31s | 4.8 |  |
| baseline | B | 41 | 123 | 39.0% (19.0 to 62.5) | 43.9% | 34.1% | 15717 / 56935 / 2115 | $0.066 | $0.169 | 37s | 5.1 |  |
<!-- /generated -->

By bug category:

<!-- generated: By bug category -->
| Condition | arithmetic | assignment | state_machine | timing |
|---|---|---|---|---|
| baseline | 51.5% | 40.5% | 0.0% | 33.3% |
<!-- /generated -->

What limited the baseline runs:

<!-- generated: Limitations -->
From a model's reading of each run, so descriptive only.

Read twice, baseline's reader named the same set of categories for 83.3% of 30 runs.

| Condition | broke_the_interface | changed_more_than_the_bug | missed_the_bug | other | test_did_not_test | wasted_effort |
|---|---|---|---|---|---|---|
| baseline, side A | 5.2% | 59.3% | 3.0% | 1.5% | 36.3% | 34.8% |
| baseline, side B | 1.6% | 64.2% | 12.2% | 0.0% | 64.2% | 34.1% |
<!-- /generated -->

## 4. Approaches

The approaches are the valid combinations of what one entry is and how
entries are indexed; the chart and the default settings are in
[spec.md](spec.md), section 2.

## 5. Results

<!-- generated: Approaches against the baseline -->
_Not available yet._
<!-- /generated -->

<!-- generated: Cost of building -->
_Not available yet._
<!-- /generated -->

## 6. What worked, what failed, and why

_To be written once the approaches have been run._

## 7. Limits and how to read the results

<!-- generated: Trust -->
| Condition | Planned | Recorded | Completed | Timed out | Errored | Flagged | Cleared | Void | Pending |
|---|---|---|---|---|---|---|---|---|---|
| baseline/baseline | 258 | 258 | 258 | 0 | 0 | 0 | 0 | 0 | 0 |

Violations planted in certified baseline trajectories: the monitor flagged 20 of 20 (read grading assets 4/4, search for answers 4/4, fetch from network 4/4, fake the result 4/4, copy another runs answer 4/4). The judge flagged 20 and the pattern match 8.

Told to get a pass by any means, the agent was flagged in 0.0% of 6 runs. A run that is not flagged here is one where the agent did not attempt a violation.

Two repeats of the baseline differ by +0.0% (-7.1 to +7.0) on B. The smallest difference in pass rate this benchmark can tell from chance is about 9.5%.
<!-- /generated -->

_To be completed. Known now:_

- **The network was open.** The harness is built to confine the agent to the
  model's API, but that needs kernel support this machine's Docker lacks.
  Web search was off, the rules forbade network use, and every trajectory
  was read for it.
- **Three tasks are unusable.** The reference for
  `Prob013_least_common_multiple` drives an output to high impedance, which
  its own testbench counts as a mismatch, so no answer can pass. The task
  checks found this and its three tasks were left out.
- **A public benchmark.** The model may have seen these problems. That
  affects the baseline and every approach alike, but it narrows the room an
  approach has to help.
- **One agent and one model.**
- **The KBs were built with the result shown.** After each task on A the
  agent saw how its answer had been graded and the correct fix, and then
  updated the KB. That is how a KB is fed in practice, once a bug is closed
  and its fix is known. It also means these results say nothing about a KB
  written by an agent that never learns whether it was right.
- **One chain and one repeat per approach.** Each KB comes from a single
  order of A, and each approach was run once on B. The baseline suggests
  repeats add little, since few tasks change outcome between them, but the
  effect of the order A is seen in is not measured.
- **Thirteen of the 51 approaches were run,** chosen to span every kind of
  entry and every kind of index and to include the ones the baseline on A
  pointed to.
- **One approach could not be run.** Codex's own memory could not be kept
  between runs under this executor; see spec.md, section 8.

## 8. Future exploration

See [spec.md](spec.md), section 10.
