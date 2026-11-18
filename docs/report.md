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
_Not available yet._
<!-- /generated -->

By bug category:

<!-- generated: By bug category -->
_Not available yet._
<!-- /generated -->

What limited the baseline runs:

<!-- generated: Limitations -->
_Not available yet._
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
_Not available yet._
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
- **The agent never learns whether its fix passed.** What a KB holds is
  therefore unverified.
- **One approach was not run.** Codex's own memory could not be kept between
  runs under this executor; see spec.md, section 8.

## 8. Future exploration

See [spec.md](spec.md), section 10.
