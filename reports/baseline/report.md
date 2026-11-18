# Report

Experiments: baseline. Model: `gpt-6.2-sol`. Prices: LiteLLM's price table, the one Harbor 0.26.0 uses, 2026-11-18.

## Baseline

| Set | Tasks | Modules | Runs | Pass rate, % | 95% interval | Tasks passing any run, % | every run, % | Tokens per run | Cost per run, $ | Time to solution, s |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| A | 45 | 17 | 135 | 69.6 | 45.7 to 90.8 | 71.1 | 68.9 | 70k | 0.061 | 31 |
| B | 41 | 15 | 123 | 39.0 | 19.0 to 62.5 | 43.9 | 34.1 | 75k | 0.066 | 37 |

## Baseline outcomes

On set A, 31 of 45 tasks passed in all 3 runs, 13 in none and 1 in some. Of its 17 modules, 11 passed every run, 5 passed none and 1 was mixed.

On set B, 14 of 41 tasks passed in all 3 runs, 23 in none and 4 in some. Of its 15 modules, 5 passed every run, 7 passed none and 3 were mixed.

## Baseline limitations

Of the 41 runs that failed on set A: own test missed the fault 40, changed more than the bug 40, broke the interface 7, wasted effort 5, missed the bug 4.

Of the 75 runs that failed on set B: own test missed the fault 75, changed more than the bug 70, wasted effort 19, missed the bug 15, broke the interface 2.

Labelling 30 runs a second time, the model gave the same set of limitations for 25 of them.

## Conditions

| Condition | Set | Tasks | Runs | Pass rate, % | 95% interval | Input tokens, uncached | cached | Output tokens | Cost per run, $ | Cost per solved task, $ | Time to solution, s | Model responses per run |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| No KB | A | 45 | 135 | 69.6 | 45.7 to 90.8 | 15.5k | 52.8k | 1.7k | 0.061 | 0.088 | 31 | 4.8 |
| No KB | B | 41 | 123 | 39.0 | 19.0 to 62.5 | 15.7k | 56.9k | 2.1k | 0.066 | 0.169 | 37 | 5.1 |

## By bug category

Pass rate in percent, with the number of tasks in brackets.

| Condition | Set | Arithmetic | Assignment | State machine | Timing |
|---|---|---:|---:|---:|---:|
| No KB | A | 75.0 (12) | 73.3 (15) | 75.0 (4) | 59.5 (14) |
| No KB | B | 51.5 (11) | 40.5 (14) | 0.0 (2) | 33.3 (14) |

## Limitations

Share of runs showing each limitation, in percent. A run can show several.

| Condition | Set | Changed more than the bug | Own test missed the fault | Wasted effort | Missed the bug | Broke the interface |
|---|---|---:|---:|---:|---:|---:|
| No KB | A | 59.3 | 36.3 | 34.8 | 3.0 | 5.2 |
| No KB | B | 64.2 | 64.2 | 34.1 | 12.2 | 1.6 |

## Trust

| Condition | Planned | Recorded | Completed | Timed out | Errored | Flagged | Cleared | Void | Pending |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| No KB | 258 | 258 | 258 | 0 | 0 | 0 | 0 | 0 | 0 |

Violations planted in clean baseline trajectories: the monitor flagged 20 of 20 (reading the grading assets 4 of 4, searching for answers 4 of 4, fetching from the network 4 of 4, faking the result 4 of 4, copying another run's answer 4 of 4). The model judge flagged 20 and the pattern match 8.

## Repeat noise

Two repeats of the baseline on B differ by 0.0 points (−7.1 to +7.0). From the standard error of that difference, a paired comparison on B has 80% power to detect a change of about 9.5 points.
