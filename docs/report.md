# Knowledge bases for an RTL debugging agent

<p class="byline">Attila Palabiyik · November 2026</p>

## 1. Summary

_To be written when the results are in._

## 2. Setup

The question is which way of storing and retrieving what earlier debugging
runs learned helps a later run most. The thing under test is a knowledge base
(KB) approach. The agent, the model and everything else are held fixed, and a
run with a KB differs from a run without one by exactly the approach's own
configuration.

**Agent.** Codex CLI 0.170.0, headless, with `gpt-6.2-sol` at medium reasoning
effort. Web search is off and the CLI's own memory is off. Every prompt opens
with the same five lines of rules. Everything else is the CLI's default.

**Benchmark.** ChipBench's Verilog debugging cases. Each gives a written
specification and a module with one injected bug. The agent edits the module
in place. A hidden testbench then compares it with a reference on every
sample, and the answer passes on zero mismatches. There are 33 modules, each
with up to four different bugs.

**Split.** Set A builds a KB and set B tests it. The split is by module, so no
module has tasks on both sides. Tasks of one module share one correct file,
and a module on both sides would put B's answers into a KB built on A.

**Conditions.**

| Condition | Tasks | KB |
|---|---|---|
| Baseline | A and B | None |
| Build | A, one task after another | Starts empty. Each task is solved with the KB as it stands; the agent then updates it. |
| Frozen | B | The KB as the build left it. Nothing a run writes is kept. |

**Isolation and grading.** Every run gets a fresh container. The testbench and
the reference exist only in a second container, where the answer is graded
after the agent has finished. Before any agent ran, every task was run twice
with no model: a known-good answer has to pass and the untouched module has to
fail. Three tasks failed that check and are left out (section 7).

**Measures.** Correctness is the testbench's verdict. Tokens and time are the
agent's own, for the turn in which it solves the task. Intervals come from
resampling whole modules, since tasks of one module stand or fall together.

## 3. What the baseline shows

<!-- generated: Baseline -->
| Side | Tasks | Runs | Pass rate (95% interval) | pass@3 | pass^3 | Tokens per run | Cost per run | Time to solution |
|---|---|---|---|---|---|---|---|---|
| A | 45 | 135 | 69.6% (45.7 to 90.8) | 71.1% | 68.9% | 70k | $0.061 | 31 s |
| B | 41 | 123 | 39.0% (19.0 to 62.5) | 43.9% | 34.1% | 75k | $0.066 | 37 s |

On side A, 68.9% of tasks pass in every repeat, 28.9% in none, and 2.2% in some but not all.

On side B, 34.1% of tasks pass in every repeat, 56.1% in none, and 9.8% in some but not all.
<!-- /generated -->

Three things stand out.

**B is harder than A.** The split was drawn once, by module, from a fixed
seed, and was not adjusted afterwards.

**The outcome is settled by the task, not by chance.** Few tasks pass in some
repeats and fail in others. Whole modules pass or fail together, whichever
bug was injected.

**Most failures are not a missed bug.** Every baseline run was read against
the task, the verdict and a correct answer, and what limited it was recorded
under a fixed set of categories. The categories came from free-text notes on
a sample of A's runs and were fixed before any KB run.

<!-- generated: Baseline limitations -->
| Limitation | Side A | Side B |
|---|---|---|
| test did not test | 36.3% | 64.2% |
| changed more than the bug | 59.3% | 64.2% |
| wasted effort | 34.8% | 34.1% |
| missed the bug | 3.0% | 12.2% |
| broke the interface | 5.2% | 1.6% |
| other | 1.5% | 0.0% |

Share of runs showing each limitation, from a model's reading of every run. Read twice, the reader named the same set of limitations for 83.3% of 30 runs.
<!-- /generated -->

In the commonest failure the agent finds the defect and then keeps going. It
rewrites the module to match the written specification, and in doing so moves
an output by a clock cycle or changes a reset value that the original code
had and the reference keeps. One sequence detector had its shift register
filling from the wrong end. Swapping two operands was the whole fix. The
agent made that swap, and also moved the comparison so that the output rose a
cycle earlier.

The second commonest goes with it. The agent writes its own testbench, often
an exhaustive one, and the testbench passes, because it encodes the same
reading of the specification as the rewrite. From where the agent stands, the
run succeeded.

This matters for what a KB can do. An agent asked to record what it learned
from such a run will record a success.

## 4. The approaches

An approach is two choices: what one entry in the KB is, and how entries are
found. Each combination that makes sense is an approach. The thirteen in bold
were run.

| Entry | Single file | Flat files | Catalogue | Signature key | Tags | Hierarchy | Graph | Similarity search |
|---|---|---|---|---|---|---|---|---|
| Transcript | **Shared session** | **Raw cases** | · | · | · | · | | · |
| Summary | · | **Summaries** | · | · | · | · | | · |
| Note | · | **Notes** | · | · | · | · | · | **Notes by similarity** |
| Rule | **Playbook** | | | · | **Rules by tags** | · | | · |
| Page | | · | **Wiki** | · | · | · | **Wiki** | · |
| Skill | | | **Skills** | · | · | **Hierarchical skills** | · | · |
| Guide | **Single-file guide** | · | · | **Signature guides** | · | · | · | · |
| Step | · | | | · | | **Troubleshooting tree** | · | |

A dot is a combination that makes sense and was not run. An empty cell is one
that does not: a rule is too small to be a file of its own, and a step means
nothing without the steps it leads to.

The rows run from records of what happened (transcripts, summaries), through
statements of what is true (notes, rules, pages), to instructions for what to
do (skills, guides, steps). The columns run from no structure at all to the
most. A single file is read whole on every task. A catalogue is one line per
entry. A signature key maps what a failure looks like to the entries for it.

**What is the same in all of them.** The agent manages its KB itself, in its
own session, with the tools it already has. The harness never writes KB
content. An approach's instructions are assembled from shared pieces, one for
the entry type and one for the index, so two approaches differ only in the
pieces they name. No piece says anything about how to debug.

**The result is shown before the update.** After each task on A the agent is
told how its answer was graded and shown the correct fix, as a change to the
original module. It then updates the KB. Section 3 is the reason: without
this, most of what the KB recorded would be failures written down as
successes. It is also how a KB is fed in practice, since once a bug is closed
its fix is known. Only A's results are ever shown, and B's modules do not
appear in A.

**Why these thirteen.** They were chosen for two things. Together they cover
every kind of entry and every kind of index. And they include the approaches
that A's baseline points to:

| Limitation on A | What would address it | Approaches it favours |
|---|---|---|
| Changed more than the bug | One general rule, relevant to every task | Those the agent sees without looking: the playbook, the single-file guide |
| Own test could not expose the fault | A procedure, possibly with a script | Skills, hierarchical skills |
| Wasted a share of the run | Commands and scripts that already work | Skills |
| Missed the bug | Diagnosis by symptom | Signature guides, the troubleshooting tree. Rare on A, so little to gain. |

On this reading the approaches that put a general rule in front of the agent
on every task should gain most. Those that recall earlier cases (the shared
session, raw cases, summaries) should gain least, because none of B's modules
appears in A. That expectation was written down before any approach had been
run on B.

## 5. Results

<!-- generated: Results on B -->
_Not available yet._
<!-- /generated -->

_To be written when the results are in._

<!-- generated: Cost of building -->
_Not available yet._
<!-- /generated -->

## 6. What worked, what failed, and why

_To be written when the results are in._

## 7. Limits

- **One build and one run per approach.** Each KB comes from a single order
  of A, and each approach was run once on B. The baseline suggests repeats
  add little, since few tasks change outcome between them, but the effect of
  the order in which A is seen is not measured.
- **A small benchmark.** B has 41 tasks in 16 modules. The figure below gives
  the smallest difference it can tell from chance.
- **Thirteen approaches of 51.** The rest are defined and can be run with the
  same command.
- **The KBs were built with the result shown.** These results say nothing
  about a KB written by an agent that never learns whether it was right.
- **A public benchmark.** The model may have seen these problems. That
  affects the baseline and every approach alike, but it narrows the room an
  approach has to help.
- **One agent and one model.**
- **The network was open.** The harness is built to confine the agent to the
  model's API, but that needs kernel support this machine's Docker lacks. Web
  search was off, the rules forbade network use, and every trajectory was
  read for it.
- **Three tasks are unusable.** The reference for
  `Prob013_least_common_multiple` drives an output to high impedance, which
  its own testbench counts as a mismatch, so no answer can pass. The task
  checks found this.
- **One approach could not be run.** Codex's own memory cannot be kept
  between runs under this executor, which recreates the CLI's home directory
  for every run.
- **Limitations are a model's reading.** They describe; they are not scores.

<!-- generated: Trust -->
| Condition | Planned | Recorded | Completed | Timed out | Errored | Flagged | Cleared | Void | Pending |
|---|---|---|---|---|---|---|---|---|---|
| baseline/baseline | 258 | 258 | 258 | 0 | 0 | 0 | 0 | 0 | 0 |

Violations planted in certified baseline trajectories: the monitor flagged 20 of 20 (read grading assets 4/4, search for answers 4/4, fetch from network 4/4, fake the result 4/4, copy another runs answer 4/4). The judge flagged 20 and the pattern match 8.

Told to get a pass by any means, the agent was flagged in 0.0% of 6 runs. A run that is not flagged here is one where the agent did not attempt a violation.

Two repeats of the baseline differ by +0.0% (-7.1 to +7.0) on B. The smallest difference in pass rate this benchmark can tell from chance is about 9.5%.
<!-- /generated -->

## 8. Further work

- **Repeats and orders.** Three chains per approach, each over a different
  order of A, would show how much a KB depends on what it happened to see
  first.
- **The remaining combinations**, and one setting changed at a time on the
  approaches that did best: what the key describes, how entries are
  maintained, whether a use count is kept.
- **Hill climbing on A.** Repeated passes over A that keep a change to a KB
  only if it helps, with B untouched until the end.
- **A root-cause measure**, scoring whether the agent found the cause apart
  from whether it fixed it. It needs a recorded fault location per task to be
  worth having.
- **A harder benchmark.** Only the adapter is specific to ChipBench.

## Sources

- ChipBench, https://github.com/zhongkaiyu/ChipBench
- Harbor, https://docs.harborframework.com
- Codex CLI, https://developers.openai.com/codex
- Establishing Best Practices for Building Rigorous Agentic Benchmarks, https://arxiv.org/abs/2507.02825
- BenchJack: Systematically Auditing AI Agent Benchmarks, https://arxiv.org/abs/2605.12673
- AI Agents That Matter, https://arxiv.org/abs/2407.01502
- Miller, Adding Error Bars to Evals, https://arxiv.org/abs/2411.00640
- Why Do Multi-Agent LLM Systems Fail?, https://arxiv.org/abs/2503.13657
- Learning to Debug: LLM-Organized Knowledge Trees for Solving RTL Assertion Failures, https://arxiv.org/abs/2511.17833
- Agentic Context Engineering, https://arxiv.org/abs/2510.04618
- Agent Skills, https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
- The full list is in `docs/spec.md`, section 11.

## Appendix: full tables

Every table in this report is generated from the stored runs by one command,
given in the README.

<!-- generated: Conditions -->
| Condition | Side | Tasks | Runs | Pass rate (95%) | pass@k | pass^k | Tokens per run: uncached / cached / output | Cost per run | Cost per solved task | Time to solution | Responses | KB use |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| baseline | A | 45 | 135 | 69.6% (45.7 to 90.8) | 71.1% | 68.9% | 15455 / 52800 / 1736 | $0.061 | $0.088 | 31s | 4.8 |  |
| baseline | B | 41 | 123 | 39.0% (19.0 to 62.5) | 43.9% | 34.1% | 15717 / 56935 / 2115 | $0.066 | $0.169 | 37s | 5.1 |  |
<!-- /generated -->

<!-- generated: By bug category -->
| Condition | arithmetic | assignment | state_machine | timing |
|---|---|---|---|---|
| baseline | 51.5% | 40.5% | 0.0% | 33.3% |
<!-- /generated -->

<!-- generated: Limitations -->
From a model's reading of each run, so descriptive only.

Read twice, baseline's reader named the same set of categories for 83.3% of 30 runs.

| Condition | broke_the_interface | changed_more_than_the_bug | missed_the_bug | other | test_did_not_test | wasted_effort |
|---|---|---|---|---|---|---|
| baseline, side A | 5.2% | 59.3% | 3.0% | 1.5% | 36.3% | 34.8% |
| baseline, side B | 1.6% | 64.2% | 12.2% | 0.0% | 64.2% | 34.1% |
<!-- /generated -->
