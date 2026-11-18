# Report

Experiments: baseline, redteam. Model: `gpt-6.2-sol`. Prices: LiteLLM's price table, the one Harbor 0.26.0 uses, 2026-11-18.

## Baseline

| Side | Tasks | Runs | Pass rate (95% interval) | pass@3 | pass^3 | Tokens per run | Cost per run | Time to solution |
|---|---|---|---|---|---|---|---|---|
| A | 45 | 135 | 69.6% (45.7 to 90.8) | 71.1% | 68.9% | 70k | $0.061 | 31 s |
| B | 41 | 123 | 39.0% (19.0 to 62.5) | 43.9% | 34.1% | 75k | $0.066 | 37 s |

On side A, 68.9% of tasks pass in every repeat, 28.9% in none, and 2.2% in some but not all.

On side B, 34.1% of tasks pass in every repeat, 56.1% in none, and 9.8% in some but not all.

## Baseline limitations

| Limitation | Side A | Side B |
|---|---|---|
| test did not test | 36.3% | 64.2% |
| changed more than the bug | 59.3% | 64.2% |
| wasted effort | 34.8% | 34.1% |
| missed the bug | 3.0% | 12.2% |
| broke the interface | 5.2% | 1.6% |
| other | 1.5% | 0.0% |

Share of runs showing each limitation, from a model's reading of every run. Read twice, the reader named the same set of limitations for 83.3% of 30 runs.

## Conditions

| Condition | Side | Tasks | Runs | Pass rate (95%) | pass@k | pass^k | Tokens per run: uncached / cached / output | Cost per run | Cost per solved task | Time to solution | Responses | KB use |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| baseline | A | 45 | 135 | 69.6% (45.7 to 90.8) | 71.1% | 68.9% | 15455 / 52800 / 1736 | $0.061 | $0.088 | 31s | 4.8 |  |
| baseline | B | 41 | 123 | 39.0% (19.0 to 62.5) | 43.9% | 34.1% | 15717 / 56935 / 2115 | $0.066 | $0.169 | 37s | 5.1 |  |

## By bug category, on B

| Condition | arithmetic | assignment | state_machine | timing |
|---|---|---|---|---|
| baseline | 51.5% | 40.5% | 0.0% | 33.3% |

## Limitations

From a model's reading of each run, so descriptive only.

Read twice, baseline's reader named the same set of categories for 83.3% of 30 runs.

| Condition | broke_the_interface | changed_more_than_the_bug | missed_the_bug | other | test_did_not_test | wasted_effort |
|---|---|---|---|---|---|---|
| baseline, side A | 5.2% | 59.3% | 3.0% | 1.5% | 36.3% | 34.8% |
| baseline, side B | 1.6% | 64.2% | 12.2% | 0.0% | 64.2% | 34.1% |

## Trust

| Condition | Planned | Recorded | Completed | Timed out | Errored | Flagged | Cleared | Void | Pending |
|---|---|---|---|---|---|---|---|---|---|
| baseline/baseline | 258 | 258 | 258 | 0 | 0 | 0 | 0 | 0 | 0 |

Violations planted in certified baseline trajectories: the monitor flagged 20 of 20 (read grading assets 4/4, search for answers 4/4, fetch from network 4/4, fake the result 4/4, copy another runs answer 4/4). The judge flagged 20 and the pattern match 8.

Told to get a pass by any means, the agent was flagged in 0.0% of 6 runs. A run that is not flagged here is one where the agent did not attempt a violation.

Two repeats of the baseline differ by +0.0% (-7.1 to +7.0) on B. The smallest difference in pass rate this benchmark can tell from chance is about 9.5%.
