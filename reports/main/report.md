# Report

Experiments: baseline, kb-guide-single-file, kb-hierarchical-skills, kb-note-similarity, kb-notes, kb-playbook, kb-raw-cases, kb-rule-tags, kb-shared-session, kb-signature-guides, kb-skills, kb-summaries, kb-troubleshooting-tree, kb-wiki. Model: `gpt-6.2-sol`. Prices: LiteLLM's price table, the one Harbor 0.26.0 uses, 2026-11-18.

## Baseline

| Set | Tasks | Modules | Runs | Pass rate, % | 95% interval | Passing any run, % | Passing every run, % | Tokens per run | Cost per run, $ | Time to solution, s |
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

## Results on B

| Approach | Runs passed | Pass rate, % | Difference, points | 95% interval | Tasks helped | Tasks harmed | Tokens, × no KB | Time, × no KB | Runs that read the KB, % |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| No KB | 48 of 123 | 39.0 |  |  |  |  |  |  |  |
| Single-file guide | 24 of 41 | 58.5 | +19.5 | +7.1 to +33.3 | 10 | 0 | 1.56 | 1.33 | in context |
| Playbook | 24 of 41 | 58.5 | +19.5 | +4.7 to +38.1 | 10 | 0 | 1.20 | 1.35 | in context |
| Notes by similarity | 23 of 41 | 56.1 | +17.1 | +4.7 to +32.6 | 9 | 0 | 1.68 | 2.05 | 100.0 |
| Skills | 23 of 41 | 56.1 | +17.1 | +4.7 to +31.8 | 9 | 0 | 1.51 | 1.36 | 100.0 |
| Notes | 22 of 41 | 53.7 | +14.6 | +2.4 to +28.6 | 8 | 0 | 1.48 | 1.38 | 100.0 |
| Shared session | 22 of 41 | 53.7 | +14.6 | +2.5 to +28.6 | 8 | 0 | 6.73 | 1.47 | in context |
| Summaries | 21 of 41 | 51.2 | +12.2 | +2.4 to +23.8 | 7 | 0 | 1.63 | 1.37 | 78.0 |
| Wiki | 21 of 41 | 51.2 | +12.2 | 0.0 to +25.6 | 7 | 0 | 1.62 | 1.16 | 95.1 |
| Hierarchical skills | 20 of 41 | 48.8 | +9.8 | 0.0 to +20.5 | 6 | 0 | 1.58 | 1.37 | 100.0 |
| Rules by tags | 20 of 41 | 48.8 | +9.8 | 0.0 to +20.9 | 6 | 0 | 1.38 | 1.43 | 100.0 |
| Signature guides | 20 of 41 | 48.8 | +9.8 | 0.0 to +20.5 | 6 | 0 | 1.37 | 1.44 | 90.2 |
| Raw cases | 18 of 41 | 43.9 | +4.9 | 0.0 to +11.9 | 4 | 0 | 1.45 | 1.42 | 97.6 |
| Troubleshooting tree | 18 of 41 | 43.9 | +4.9 | 0.0 to +11.9 | 4 | 0 | 1.39 | 1.36 | 100.0 |

## Seen and unseen modules

| Approach | A, module met before, 28 tasks | A, module new, 17 tasks | B, every module new, 41 tasks |
|---|---:|---:|---:|
| Single-file guide | +17.9 (+3.7 to +35.7) | −7.8 (−21.6 to 0.0) | +19.5 (+7.1 to +33.3) |
| Playbook | +7.1 (−7.1 to +25.9) | −2.0 (−5.9 to 0.0) | +19.5 (+4.7 to +38.1) |
| Notes by similarity | +10.7 (0.0 to +28.0) | −2.0 (−5.9 to 0.0) | +17.1 (+4.7 to +32.6) |
| Skills | +10.7 (0.0 to +28.0) | −2.0 (−19.6 to +15.7) | +17.1 (+4.7 to +31.8) |
| Notes | +3.6 (−7.4 to +16.1) | −2.0 (−5.9 to 0.0) | +14.6 (+2.4 to +28.6) |
| Shared session | +10.7 (0.0 to +28.0) | +3.9 (−5.9 to +17.6) | +14.6 (+2.5 to +28.6) |
| Summaries | +7.1 (0.0 to +22.2) | −2.0 (−5.9 to 0.0) | +12.2 (+2.4 to +23.8) |
| Wiki | +10.7 (0.0 to +28.0) | −2.0 (−5.9 to 0.0) | +12.2 (0.0 to +25.6) |
| Hierarchical skills | +7.1 (−7.1 to +25.9) | −2.0 (−5.9 to 0.0) | +9.8 (0.0 to +20.5) |
| Rules by tags | +7.1 (−7.1 to +25.9) | −2.0 (−5.9 to 0.0) | +9.8 (0.0 to +20.9) |
| Signature guides | +10.7 (0.0 to +28.0) | −2.0 (−5.9 to 0.0) | +9.8 (0.0 to +20.5) |
| Raw cases | +3.6 (0.0 to +11.1) | −2.0 (−5.9 to 0.0) | +4.9 (0.0 to +11.9) |
| Troubleshooting tree | +3.6 (−10.0 to +21.4) | −2.0 (−5.9 to 0.0) | +4.9 (0.0 to +11.9) |

## Conditions

| Condition | Set | Tasks | Runs | Pass rate, % | 95% interval | Uncached in | Cached in | Output | $ / run | $ / solved | Time, s | Responses |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| No KB | A | 45 | 135 | 69.6 | 45.7 to 90.8 | 15.5k | 52.8k | 1.7k | 0.061 | 0.088 | 31 | 4.8 |
| No KB | B | 41 | 123 | 39.0 | 19.0 to 62.5 | 15.7k | 56.9k | 2.1k | 0.066 | 0.169 | 37 | 5.1 |
| Single-file guide, build | A | 45 | 45 | 77.8 | 63.0 to 91.1 | 20.1k | 71.9k | 1.7k | 0.074 | 0.095 | 33 | 5.0 |
| Single-file guide | B | 41 | 41 | 58.5 | 39.0 to 78.4 | 23.3k | 91.5k | 2.2k | 0.089 | 0.152 | 49 | 5.3 |
| Hierarchical skills, build | A | 45 | 45 | 73.3 | 53.1 to 90.7 | 18.9k | 80.5k | 1.9k | 0.074 | 0.101 | 36 | 6.0 |
| Hierarchical skills | B | 41 | 41 | 48.8 | 27.3 to 72.1 | 21.5k | 98.8k | 2.4k | 0.087 | 0.179 | 51 | 6.5 |
| Notes by similarity, build | A | 45 | 45 | 75.6 | 55.3 to 93.0 | 17.0k | 77.8k | 1.9k | 0.069 | 0.092 | 43 | 6.3 |
| Notes by similarity | B | 41 | 41 | 56.1 | 35.7 to 77.5 | 18.3k | 110.7k | 2.4k | 0.080 | 0.143 | 72 | 8.2 |
| Notes, build | A | 45 | 45 | 71.1 | 50.0 to 89.4 | 17.9k | 79.1k | 2.0k | 0.073 | 0.102 | 38 | 6.2 |
| Notes | B | 41 | 41 | 53.7 | 31.7 to 76.3 | 19.3k | 90.0k | 2.3k | 0.081 | 0.151 | 51 | 6.5 |
| Playbook, build | A | 45 | 45 | 73.3 | 53.1 to 90.7 | 17.2k | 60.2k | 1.7k | 0.066 | 0.090 | 33 | 4.9 |
| Playbook | B | 41 | 41 | 58.5 | 36.4 to 81.4 | 18.5k | 69.1k | 2.0k | 0.073 | 0.125 | 50 | 5.1 |
| Raw cases, build | A | 45 | 45 | 71.1 | 48.8 to 90.7 | 18.4k | 82.0k | 1.9k | 0.073 | 0.103 | 36 | 6.3 |
| Raw cases | B | 41 | 41 | 43.9 | 22.7 to 67.5 | 19.1k | 89.6k | 2.3k | 0.080 | 0.182 | 51 | 6.5 |
| Rules by tags, build | A | 45 | 45 | 73.3 | 53.1 to 90.7 | 18.0k | 73.9k | 2.0k | 0.072 | 0.098 | 37 | 5.8 |
| Rules by tags | B | 41 | 41 | 48.8 | 27.3 to 71.4 | 19.6k | 82.6k | 2.4k | 0.081 | 0.166 | 51 | 6.0 |
| Shared session, build | A | 45 | 45 | 77.8 | 57.1 to 95.3 | 3.0k | 268.6k | 1.1k | 0.045 | 0.058 | 28 | 3.8 |
| Shared session | B | 41 | 41 | 53.7 | 33.3 to 75.6 | 2.8k | 494.8k | 1.4k | 0.071 | 0.132 | 51 | 3.7 |
| Signature guides, build | A | 45 | 45 | 75.6 | 55.3 to 93.0 | 17.9k | 68.5k | 1.8k | 0.069 | 0.092 | 35 | 5.4 |
| Signature guides | B | 41 | 41 | 48.8 | 27.3 to 72.1 | 19.5k | 81.5k | 2.2k | 0.079 | 0.162 | 52 | 5.8 |
| Skills, build | A | 45 | 45 | 75.6 | 55.3 to 92.7 | 18.9k | 74.1k | 1.9k | 0.074 | 0.097 | 36 | 5.6 |
| Skills | B | 41 | 41 | 56.1 | 35.0 to 78.4 | 22.4k | 90.6k | 2.3k | 0.088 | 0.157 | 49 | 5.8 |
| Summaries, build | A | 45 | 45 | 73.3 | 52.3 to 91.7 | 17.6k | 90.0k | 2.1k | 0.074 | 0.101 | 40 | 6.9 |
| Summaries | B | 41 | 41 | 51.2 | 31.7 to 72.5 | 18.9k | 104.9k | 2.7k | 0.084 | 0.165 | 50 | 7.5 |
| Troubleshooting tree, build | A | 45 | 45 | 71.1 | 50.0 to 89.4 | 17.3k | 75.7k | 1.9k | 0.070 | 0.098 | 37 | 6.1 |
| Troubleshooting tree | B | 41 | 41 | 43.9 | 22.7 to 67.5 | 18.1k | 85.5k | 2.2k | 0.076 | 0.172 | 49 | 6.6 |
| Wiki, build | A | 45 | 45 | 75.6 | 55.3 to 93.0 | 19.3k | 86.4k | 2.0k | 0.077 | 0.102 | 38 | 6.3 |
| Wiki | B | 41 | 41 | 51.2 | 29.3 to 75.0 | 21.5k | 99.9k | 2.3k | 0.087 | 0.170 | 42 | 6.6 |

## Approaches against the baseline on B (13 compared)

| Approach | Tasks | Pass rate, points | 95% interval | Helped / harmed / same | Tokens, × | 95% interval | Cost, × | 95% interval | Time, × | 95% interval |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Single-file guide | 41 | +19.5 | +7.1 to +33.3 | 10 / 0 / 31 | 1.56 | 1.48 to 1.65 | 1.36 | 1.30 to 1.41 | 1.33 | 1.23 to 1.43 |
| Playbook | 41 | +19.5 | +4.7 to +38.1 | 10 / 0 / 31 | 1.20 | 1.15 to 1.25 | 1.11 | 1.07 to 1.16 | 1.35 | 1.24 to 1.45 |
| Notes by similarity | 41 | +17.1 | +4.7 to +32.6 | 9 / 0 / 32 | 1.68 | 1.55 to 1.81 | 1.21 | 1.16 to 1.25 | 2.05 | 1.87 to 2.24 |
| Skills | 41 | +17.1 | +4.7 to +31.8 | 9 / 0 / 32 | 1.51 | 1.43 to 1.59 | 1.33 | 1.27 to 1.39 | 1.36 | 1.27 to 1.45 |
| Notes | 41 | +14.6 | +2.4 to +28.6 | 8 / 0 / 33 | 1.48 | 1.37 to 1.60 | 1.21 | 1.15 to 1.28 | 1.38 | 1.28 to 1.51 |
| Shared session | 41 | +14.6 | +2.5 to +28.6 | 8 / 0 / 33 | 6.73 | 6.12 to 7.32 | 1.08 | 1.02 to 1.15 | 1.47 | 1.30 to 1.65 |
| Summaries | 41 | +12.2 | +2.4 to +23.8 | 7 / 0 / 34 | 1.63 | 1.49 to 1.79 | 1.27 | 1.21 to 1.33 | 1.37 | 1.31 to 1.44 |
| Wiki | 41 | +12.2 | 0.0 to +25.6 | 7 / 0 / 34 | 1.62 | 1.51 to 1.73 | 1.32 | 1.27 to 1.36 | 1.16 | 1.09 to 1.23 |
| Hierarchical skills | 41 | +9.8 | 0.0 to +20.5 | 6 / 0 / 35 | 1.58 | 1.43 to 1.72 | 1.31 | 1.24 to 1.38 | 1.37 | 1.27 to 1.47 |
| Rules by tags | 41 | +9.8 | 0.0 to +20.9 | 6 / 0 / 35 | 1.38 | 1.30 to 1.45 | 1.22 | 1.18 to 1.26 | 1.43 | 1.31 to 1.57 |
| Signature guides | 41 | +9.8 | 0.0 to +20.5 | 6 / 0 / 35 | 1.37 | 1.29 to 1.45 | 1.19 | 1.15 to 1.24 | 1.44 | 1.34 to 1.55 |
| Raw cases | 41 | +4.9 | 0.0 to +11.9 | 4 / 0 / 37 | 1.45 | 1.36 to 1.55 | 1.20 | 1.16 to 1.25 | 1.42 | 1.36 to 1.49 |
| Troubleshooting tree | 41 | +4.9 | 0.0 to +11.9 | 4 / 0 / 37 | 1.39 | 1.31 to 1.49 | 1.14 | 1.10 to 1.19 | 1.36 | 1.30 to 1.43 |

## Cost of building

| Approach | Extra tokens | Extra cost, $ | Extra time, min | Tasks after which the KB changed, % | Pays for itself after |
|---|---:|---:|---:|---:|---|
| Single-file guide | 4.90M | 1.63 | 18 | 93.3 | never |
| Playbook | 3.43M | 0.93 | 15 | 100.0 | never |
| Notes by similarity | 4.36M | 1.15 | 29 | 100.0 | never |
| Skills | 6.14M | 1.96 | 25 | 97.8 | never |
| Notes | 4.22M | 1.27 | 21 | 97.8 | never |
| Shared session | 9.12M | −0.72 | −2 | 100.0 | never |
| Summaries | 4.58M | 1.26 | 22 | 100.0 | never |
| Wiki | 5.82M | 2.10 | 26 | 100.0 | never |
| Hierarchical skills | 6.79M | 2.10 | 26 | 100.0 | never |
| Rules by tags | 4.37M | 1.26 | 21 | 97.8 | never |
| Signature guides | 4.33M | 1.41 | 22 | 100.0 | never |
| Raw cases | 1.45M | 0.53 | 4 | 100.0 | never |
| Troubleshooting tree | 4.52M | 1.36 | 23 | 97.8 | never |

## By bug category

| Condition | Set | Arithmetic | Assignment | State machine | Timing |
|---|---|---:|---:|---:|---:|
| No KB | A | 75.0 (12) | 73.3 (15) | 75.0 (4) | 59.5 (14) |
| No KB | B | 51.5 (11) | 40.5 (14) | 0.0 (2) | 33.3 (14) |
| Single-file guide | B | 72.7 (11) | 64.3 (14) | 0.0 (2) | 50.0 (14) |
| Playbook | B | 81.8 (11) | 57.1 (14) | 0.0 (2) | 50.0 (14) |
| Notes by similarity | B | 72.7 (11) | 57.1 (14) | 0.0 (2) | 50.0 (14) |
| Skills | B | 72.7 (11) | 50.0 (14) | 0.0 (2) | 57.1 (14) |
| Notes | B | 72.7 (11) | 50.0 (14) | 0.0 (2) | 50.0 (14) |
| Shared session | B | 72.7 (11) | 57.1 (14) | 0.0 (2) | 42.9 (14) |
| Summaries | B | 72.7 (11) | 42.9 (14) | 0.0 (2) | 50.0 (14) |
| Wiki | B | 72.7 (11) | 50.0 (14) | 0.0 (2) | 42.9 (14) |
| Hierarchical skills | B | 63.6 (11) | 50.0 (14) | 0.0 (2) | 42.9 (14) |
| Rules by tags | B | 63.6 (11) | 57.1 (14) | 0.0 (2) | 35.7 (14) |
| Signature guides | B | 63.6 (11) | 50.0 (14) | 0.0 (2) | 42.9 (14) |
| Raw cases | B | 63.6 (11) | 42.9 (14) | 0.0 (2) | 35.7 (14) |
| Troubleshooting tree | B | 63.6 (11) | 42.9 (14) | 0.0 (2) | 35.7 (14) |

## Limitations

| Condition | Set | KB did not help | Changed more than the bug | Own test missed the fault | Wasted effort | Missed the bug | Ignored the KB | Misled by the KB | Broke the interface |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|
| No KB | A | 0.0 | 59.3 | 36.3 | 34.8 | 3.0 | 0.0 | 0.0 | 5.2 |
| No KB | B | 0.0 | 64.2 | 64.2 | 34.1 | 12.2 | 0.0 | 0.0 | 1.6 |
| Single-file guide | B | 0.0 | 41.5 | 43.9 | 53.7 | 14.6 | 4.9 | 0.0 | 2.4 |
| Hierarchical skills | B | 34.1 | 46.3 | 53.7 | 51.2 | 14.6 | 7.3 | 0.0 | 2.4 |
| Notes by similarity | B | 51.2 | 43.9 | 46.3 | 58.5 | 12.2 | 4.9 | 0.0 | 0.0 |
| Notes | B | 56.1 | 41.5 | 51.2 | 24.4 | 14.6 | 2.4 | 7.3 | 0.0 |
| Playbook | B | 0.0 | 39.0 | 41.5 | 51.2 | 9.8 | 0.0 | 0.0 | 0.0 |
| Raw cases | B | 92.7 | 58.5 | 61.0 | 46.3 | 14.6 | 4.9 | 0.0 | 0.0 |
| Rules by tags | B | 36.6 | 48.8 | 51.2 | 61.0 | 14.6 | 2.4 | 0.0 | 4.9 |
| Shared session | B | 0.0 | 46.3 | 53.7 | 0.0 | 12.2 | 0.0 | 0.0 | 2.4 |
| Signature guides | B | 39.0 | 46.3 | 53.7 | 53.7 | 17.1 | 2.4 | 0.0 | 0.0 |
| Skills | B | 19.5 | 46.3 | 46.3 | 43.9 | 12.2 | 0.0 | 0.0 | 0.0 |
| Summaries | B | 31.7 | 51.2 | 51.2 | 36.6 | 9.8 | 7.3 | 2.4 | 4.9 |
| Troubleshooting tree | B | 29.3 | 53.7 | 58.5 | 39.0 | 9.8 | 7.3 | 4.9 | 0.0 |
| Wiki | B | 43.9 | 48.8 | 51.2 | 43.9 | 12.2 | 2.4 | 0.0 | 2.4 |

## Limitation changes

| Approach | Changed more than the bug: resolved | introduced | Own test missed the fault: resolved | introduced | Wasted effort: resolved | introduced | Missed the bug: resolved | introduced |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Single-file guide | 23.6 | 0.8 | 20.3 | 0.0 | 11.4 | 30.9 | 0.0 | 2.4 |
| Playbook | 25.2 | 0.0 | 22.8 | 0.0 | 15.4 | 32.5 | 4.9 | 2.4 |
| Notes by similarity | 22.8 | 2.4 | 17.9 | 0.0 | 8.9 | 33.3 | 2.4 | 2.4 |
| Skills | 21.1 | 3.3 | 17.9 | 0.0 | 13.0 | 22.8 | 4.9 | 4.9 |
| Notes | 22.8 | 0.0 | 13.0 | 0.0 | 28.5 | 18.7 | 0.0 | 2.4 |
| Shared session | 20.3 | 2.4 | 14.6 | 4.1 | 34.1 | 0.0 | 1.6 | 1.6 |
| Summaries | 15.4 | 2.4 | 13.0 | 0.0 | 17.1 | 19.5 | 3.3 | 0.8 |
| Wiki | 16.3 | 0.8 | 13.0 | 0.0 | 13.8 | 23.6 | 2.4 | 2.4 |
| Hierarchical skills | 17.9 | 0.0 | 10.6 | 0.0 | 13.0 | 30.1 | 0.0 | 2.4 |
| Rules by tags | 15.4 | 0.0 | 13.0 | 0.0 | 9.8 | 36.6 | 0.0 | 2.4 |
| Signature guides | 17.9 | 0.0 | 10.6 | 0.0 | 18.7 | 38.2 | 0.0 | 4.9 |
| Raw cases | 8.1 | 2.4 | 4.9 | 1.6 | 17.1 | 29.3 | 0.8 | 3.3 |
| Troubleshooting tree | 10.6 | 0.0 | 5.7 | 0.0 | 17.1 | 22.0 | 2.4 | 0.0 |

## KB contents

| Approach | Files | Words | Largest file | Words in it | Session transcripts kept |
|---|---:|---:|---|---:|---:|
| Single-file guide | 1 | 5,759 | `AGENTS.md` | 5,759 | 0 |
| Playbook | 1 | 1,949 | `AGENTS.md` | 1,949 | 0 |
| Notes by similarity | 14 | 11,714 | `entries/.kbsearch/index.json` | 5,060 | 0 |
| Skills | 5 | 6,856 | `skills/debug-verilog-cycle-alignment/SKILL.md` | 4,759 | 0 |
| Notes | 16 | 6,809 | `entries/014-preserve-pipelined-fsm-timing.md` | 931 | 0 |
| Shared session | 0 | 0 |  | 0 | 1 |
| Summaries | 79 | 13,664 | `entries/5-grouped-sequence-detector-reference-reset.md` | 286 | 0 |
| Wiki | 13 | 10,746 | `entries/width-converter-valid.md` | 1,663 | 0 |
| Hierarchical skills | 10 | 7,122 | `skills/debug-hdl-fsms/registered-output-timing/SKILL.md` | 3,620 | 0 |
| Rules by tags | 25 | 3,595 | `entries/pipeline-output-register.md` | 344 | 0 |
| Signature guides | 21 | 11,431 | `entries/moore-output-timing-and-async-reset.md` | 1,247 | 0 |
| Raw cases | 0 | 0 |  | 0 | 45 |
| Troubleshooting tree | 32 | 8,708 | `entries/fsm/transition-output-timing.md` | 681 | 0 |

## Trust

| Condition | Planned | Recorded | Completed | Timed out | Errored | Flagged | Cleared | Void | Pending |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| No KB | 258 | 258 | 258 | 0 | 0 | 0 | 0 | 0 | 0 |
| Shared session, build | 45 | 45 | 45 | 0 | 0 | 0 | 0 | 0 | 0 |
| Shared session | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Shared session, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Raw cases, build | 45 | 45 | 45 | 0 | 0 | 7 | 7 | 0 | 0 |
| Raw cases | 41 | 41 | 41 | 0 | 0 | 1 | 1 | 0 | 0 |
| Raw cases, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Summaries, build | 45 | 45 | 45 | 0 | 0 | 19 | 19 | 0 | 0 |
| Summaries | 41 | 41 | 41 | 0 | 0 | 11 | 11 | 0 | 0 |
| Summaries, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Notes, build | 45 | 45 | 45 | 0 | 0 | 7 | 7 | 0 | 0 |
| Notes | 41 | 41 | 41 | 0 | 0 | 3 | 3 | 0 | 0 |
| Notes, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Notes by similarity, build | 45 | 45 | 45 | 0 | 0 | 5 | 5 | 0 | 0 |
| Notes by similarity | 41 | 41 | 41 | 0 | 0 | 5 | 5 | 0 | 0 |
| Notes by similarity, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Playbook, build | 45 | 45 | 45 | 0 | 0 | 2 | 2 | 0 | 0 |
| Playbook | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Playbook, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Rules by tags, build | 45 | 45 | 45 | 0 | 0 | 5 | 5 | 0 | 0 |
| Rules by tags | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Rules by tags, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Wiki, build | 45 | 45 | 45 | 0 | 0 | 4 | 4 | 0 | 0 |
| Wiki | 41 | 41 | 41 | 0 | 0 | 2 | 2 | 0 | 0 |
| Wiki, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Skills, build | 45 | 45 | 45 | 0 | 0 | 7 | 7 | 0 | 0 |
| Skills | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Skills, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Hierarchical skills, build | 45 | 45 | 45 | 0 | 0 | 9 | 9 | 0 | 0 |
| Hierarchical skills | 41 | 41 | 41 | 0 | 0 | 2 | 2 | 0 | 0 |
| Hierarchical skills, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Single-file guide, build | 45 | 45 | 45 | 0 | 0 | 3 | 3 | 0 | 0 |
| Single-file guide | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Single-file guide, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Signature guides, build | 45 | 45 | 45 | 0 | 0 | 2 | 2 | 0 | 0 |
| Signature guides | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Signature guides, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Troubleshooting tree, build | 45 | 45 | 45 | 0 | 0 | 6 | 6 | 0 | 0 |
| Troubleshooting tree | 41 | 41 | 41 | 0 | 0 | 0 | 0 | 0 | 0 |
| Troubleshooting tree, empty KB | 41 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |

Monitor findings: grader targeting 1, kb answer 35, outside answer 34, rule violation 69.

Violations planted in clean baseline trajectories: the monitor flagged 20 of 20 (reading the grading assets 4 of 4, searching for answers 4 of 4, fetching from the network 4 of 4, faking the result 4 of 4, copying another run's answer 4 of 4). The model judge flagged 20 and the pattern match 8.

## Repeat noise

Two repeats of the baseline on B differ by 0.0 points (−7.1 to +7.0). From the standard error of that difference, a paired comparison on B has 80% power to detect a change of about 9.5 points.
