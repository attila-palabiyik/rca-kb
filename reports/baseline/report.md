# Report

Experiments: baseline, redteam. Model: `gpt-6.2-sol`. Prices: LiteLLM's price table, the one Harbor 0.26.0 uses, 2026-11-18.

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
