# Report

**Provisional.** 1 runs are not yet certified, so results are by Verdict alone.

Experiments: smoke. Model: `gpt-6.2-sol`. Prices: LiteLLM's price table, the one Harbor 0.26.0 uses, 2026-11-18.

## Conditions

| Condition | Side | Tasks | Runs | Pass rate (95%) | pass@k | pass^k | Tokens per run: uncached / cached / output | Cost per run | Cost per solved task | Time to solution | Responses | KB use |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| smoke/build | A | 3 | 3 | 33.3% (0.0 to 100.0) | 33.3% | 33.3% | 16497 / 75807 / 2044 | $0.069 | $0.208 | 37s | 6.3 | 100.0% |
| smoke/empty | B | 3 | 3 | 0.0% (0.0 to 0.0) | 0.0% | 0.0% | 15330 / 63342 / 1731 | $0.062 |  | 31s | 5.7 | 100.0% |
| smoke/eval | B | 3 | 3 | 0.0% (0.0 to 0.0) | 0.0% | 0.0% | 16641 / 85850 / 2404 | $0.074 |  | 44s | 7.0 | 100.0% |

## Approaches against the baseline on B (1 compared)

| Approach | Tasks | Pass rate difference (95%) | Helped / harmed / unchanged | Token ratio | Time ratio | Difference against its empty KB | Smallest detectable difference |
|---|---|---|---|---|---|---|---|

## Cost of building

| Approach | Chains | Extra tokens per chain | Extra cost per chain | Extra time per chain | Contribution rate | Break-even |
|---|---|---|---|---|---|---|
| smoke | 1 | 477731 | $0.26 | 2.7 min | 100.0% |  |

## Trust

| Condition | Planned | Recorded | Completed | Timed out | Errored | Flagged | Cleared | Void | Pending |
|---|---|---|---|---|---|---|---|---|---|
| smoke/build | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 1 |
| smoke/eval | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
| smoke/empty | 3 | 3 | 3 | 0 | 0 | 0 | 0 | 0 | 0 |
