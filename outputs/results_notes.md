# Results Notes

## Core Claim

Reliability-aware routing trades a small latency penalty for higher route availability. The availability gain can reduce availability-adjusted effective latency when risky shortcuts are present.

## Current Experiment Summary

- Rows analyzed: 81
- Mean availability gain: 0.0673
- Mean raw latency penalty: 1.1860 ms
- Mean effective latency improvement: 5.3268 ms
- Positive effective-latency improvement rate: 54.3%
- Effective-latency outcomes: 44 positive, 27 zero, 10 negative.
- Best effective-latency improvement: 28.8337 ms at 6 planes, 12 satellites per plane, duty cycle 0.45, shortcut-link availability 0.20, reliability weight 0.30.
- Maximum availability gain: 0.2721 at reliability weight 0.90 and shortcut-link availability 0.20.
- Worst effective-latency improvement: -3.0200 ms at reliability weight 0.90 and shortcut-link availability 0.20.

## Descriptive Statistics

| Metric | cases | mean | std | observed range |
|---|---:|---:|---:|---:|
| Availability gain | 81 | 0.0673 | 0.0755 | [0.0000, 0.2721] |
| Raw latency penalty (ms) | 81 | 1.1860 | 1.4769 | [0.0000, 5.7440] |
| Effective-latency improvement (ms) | 81 | 5.3268 | 7.9243 | [-3.0200, 28.8337] |

- Pearson correlation over all design cells: 0.3676.
- Pearson correlation after excluding zero-tradeoff ties (54 cells): 0.1309.

## Thesis Claims

- Reliability-aware routing improves mean route availability, but the improvement is modest on average and must be interpreted as a tradeoff.
- The largest effective-latency gains occur when the latency-only baseline is attracted to low-availability shortcut links.
- Increasing the reliability weight improves availability slightly, but it can reduce effective-latency improvement because the route may pay too much raw latency.
- Negative effective-latency improvement appears in 10 of 81 cases, so the method should be presented as scenario-dependent rather than universally dominant.

## Parameter Sensitivity

### Reliability weight

| ReliabilityWeight | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) |
|---:|---:|---:|---:|---:|
| 0.30 | 27 | 0.0645 +/- 0.0746 | 0.7764 +/- 1.1379 | 5.7222 +/- 8.0270 |
| 0.60 | 27 | 0.0678 +/- 0.0775 | 1.0560 +/- 1.4631 | 5.5193 +/- 7.8572 |
| 0.90 | 27 | 0.0696 +/- 0.0772 | 1.7257 +/- 1.6680 | 4.7387 +/- 8.1538 |

### Shortcut-link availability

| ShortcutRiskAvailability | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) |
|---:|---:|---:|---:|---:|
| 0.20 | 27 | 0.0827 +/- 0.0921 | 1.1860 +/- 1.4958 | 10.4448 +/- 11.0445 |
| 0.35 | 27 | 0.0673 +/- 0.0739 | 1.1860 +/- 1.4958 | 4.0472 +/- 4.6387 |
| 0.50 | 27 | 0.0519 +/- 0.0558 | 1.1860 +/- 1.4958 | 1.4882 +/- 2.3480 |

### Contact duty cycle

| ContactDutyCycle | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) |
|---:|---:|---:|---:|---:|
| 0.45 | 27 | 0.1049 +/- 0.0920 | 2.1519 +/- 1.9993 | 8.9647 +/- 10.6198 |
| 0.65 | 27 | 0.0610 +/- 0.0617 | 1.1078 +/- 0.8836 | 4.0157 +/- 5.5019 |
| 0.85 | 27 | 0.0359 +/- 0.0524 | 0.2984 +/- 0.3750 | 2.9999 +/- 5.3864 |

### Constellation size

| Constellation | nodes | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) | route-change delta, mean +/- std |
|---:|---:|---:|---:|---:|---:|---:|
| 4x8 | 32 | 27 | 0.1173 +/- 0.0944 | 1.8774 +/- 2.1300 | 6.4046 +/- 8.1870 | -0.7778 +/- 1.2506 |
| 6x12 | 72 | 27 | 0.0836 +/- 0.0346 | 1.2971 +/- 0.5586 | 10.0316 +/- 8.1424 | 1.7778 +/- 2.0255 |
| 8x20 | 160 | 27 | 0.0010 +/- 0.0022 | 0.3836 +/- 0.8277 | -0.4559 +/- 0.9858 | 0.7778 +/- 1.9081 |

## Route Stability

| Metric | cases | mean | std | observed range |
|---|---:|---:|---:|---:|
| Latency-only route changes | 81 | 4.5556 | 3.3578 | [0.0000, 8.0000] |
| Reliability-aware route changes | 81 | 5.1481 | 3.4932 | [0.0000, 10.0000] |
| Paired route-change delta | 81 | 0.5926 | 2.0358 | [-3.0000, 6.0000] |

- Reliability-aware routing has fewer changes in 12 cases, more in 27 cases, and ties in 42 cases.

## Robustness Summary

| Experiment | cases | mean effective-latency improvement (ms) | std (ms) | observed range (ms) |
|---|---:|---:|---:|---:|
| Main experiment | 81 | 5.3268 | 7.9243 | [-3.0200, 28.8337] |
| Seed robustness | 405 | 9.9217 | 15.3476 | [-6.1821, 70.6645] |
| Route-pair robustness | 405 | 17.2476 | 31.6448 | [-3.0200, 205.7436] |

### Seed-level means

| Seed | cases | availability gain | latency penalty (ms) | effective-latency improvement (ms) | baseline route changes | reliable route changes |
|---:|---:|---:|---:|---:|---:|---:|
| 11 | 81 | 0.1323 | 1.6002 | 12.2357 | 4.7778 | 6.1481 |
| 23 | 81 | 0.0935 | 1.7973 | 7.4552 | 6.0000 | 7.2593 |
| 42 | 81 | 0.0673 | 1.1860 | 5.3268 | 4.5556 | 5.1481 |
| 77 | 81 | 0.1686 | 2.3967 | 12.4996 | 5.4444 | 5.8148 |
| 101 | 81 | 0.1689 | 2.5442 | 12.0911 | 5.2222 | 6.0000 |

### Route-pair-level means

| Source | Destination | cases | availability gain | latency penalty (ms) | effective-latency improvement (ms) | baseline route changes | reliable route changes |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 1 | 16 | 81 | 0.0673 | 1.1860 | 5.3268 | 4.5556 | 5.1481 |
| 2 | 17 | 81 | 0.0797 | 0.8627 | 6.5651 | 5.4444 | 5.4444 |
| 4 | 20 | 81 | 0.1118 | 1.9524 | 9.3349 | 4.8889 | 6.0370 |
| 8 | 24 | 81 | 0.1933 | 2.8265 | 21.4929 | 7.0000 | 8.7778 |
| 12 | 28 | 81 | 0.1950 | 2.5247 | 43.5183 | 9.7778 | 9.2222 |

## Time-Horizon Sensitivity

| Time steps | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) | positive cases (%) | baseline route-change rate | reliable route-change rate | rate delta |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 12 | 81 | 0.0673 +/- 0.0755 | 1.1860 +/- 1.4769 | 5.3268 +/- 7.9243 | 54.3 | 0.4141 | 0.4680 | 0.0539 |
| 50 | 81 | 0.0668 +/- 0.0563 | 1.0650 +/- 0.9002 | 5.5931 +/- 7.3758 | 66.7 | 0.4558 | 0.4928 | 0.0370 |
| 100 | 81 | 0.0700 +/- 0.0572 | 1.0570 +/- 0.8625 | 5.7104 +/- 7.3566 | 66.7 | 0.4534 | 0.4905 | 0.0370 |

- Mean availability gain is positive at every tested horizon: true.
- Mean effective-latency improvement is positive at every tested horizon: true.

## Controlled Constellation-Size Sensitivity

| Constellation | endpoints | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) | route-change delta, mean +/- std |
|---:|---:|---:|---:|---:|---:|---:|
| 4x8 | 1-13 | 27 | 0.1222 +/- 0.0412 | 1.6879 +/- 1.1284 | 13.1458 +/- 10.7253 | 0.2222 +/- 1.0500 |
| 6x12 | 1-19 | 27 | 0.1314 +/- 0.0387 | 2.0880 +/- 1.3891 | 23.4609 +/- 16.1385 | 0.4444 +/- 2.1543 |
| 8x20 | 1-31 | 27 | 0.1010 +/- 0.0439 | 2.7975 +/- 1.7951 | 34.7455 +/- 39.9087 | 1.3333 +/- 0.4804 |

## Topology-Only Route-Variability Ablation

| Contact duty cycle | cases | baseline route-change rate, mean +/- std | reliability-aware route-change rate, mean +/- std |
|---:|---:|---:|---:|
| 0.45 | 5 | 0.4061 +/- 0.0407 | 0.4061 +/- 0.0407 |
| 0.65 | 5 | 0.3354 +/- 0.0085 | 0.3354 +/- 0.0085 |
| 0.85 | 5 | 0.2505 +/- 0.0111 | 0.2505 +/- 0.0111 |
| 1.00 | 5 | 0.0000 +/- 0.0000 | 0.0000 +/- 0.0000 |

- Dynamic contact windows produce route changes: true.
- Static full-contact control has no route changes: true.

## Reliability-Stress Ablation

| Risky shortcut availability | cases | availability gain, mean +/- std | latency penalty, mean +/- std (ms) | effective-latency improvement, mean +/- std (ms) | baseline risky-path rate | reliable risky-path rate |
|---:|---:|---:|---:|---:|---:|---:|
| 0.20 | 27 | 0.0827 +/- 0.0921 | 1.1860 +/- 1.4958 | 10.4448 +/- 11.0445 | 12.0% | 0.0% |
| 0.35 | 27 | 0.0673 +/- 0.0739 | 1.1860 +/- 1.4958 | 4.0472 +/- 4.6387 | 12.0% | 0.0% |
| 0.50 | 27 | 0.0519 +/- 0.0558 | 1.1860 +/- 1.4958 | 1.4882 +/- 2.3480 | 12.0% | 0.0% |
| 0.60 | 27 | 0.0404 +/- 0.0432 | 1.1058 +/- 1.4491 | 0.5323 +/- 1.7280 | 12.0% | 0.6% |
| 0.70 | 27 | 0.0299 +/- 0.0314 | 1.0479 +/- 1.4205 | -0.0956 +/- 1.5265 | 12.0% | 1.2% |
| 0.80 | 27 | 0.0199 +/- 0.0206 | 0.8483 +/- 1.2166 | -0.3190 +/- 1.3096 | 12.0% | 2.8% |
| 0.90 | 27 | 0.0120 +/- 0.0124 | 0.6203 +/- 0.8036 | -0.3624 +/- 0.8572 | 12.0% | 7.1% |

- No-stress control: mean effective-latency improvement -0.6542 +/- 1.4714 ms; outcomes 5 positive, 8 zero, 14 negative.
- Across stressed snapshots, the latency-only route uses a risky shortcut in 12.0% of snapshots and the reliability-aware route in 1.7%.
- Mean snapshot-level effective improvement is 21.2840 ms when the baseline uses a risky shortcut and -0.3570 ms otherwise.
- The observed mean changes sign between shortcut availabilities 0.60 and 0.70; linear interpolation places the descriptive zero crossing at 0.6848.

## Interpretation

- Shortest-path routing is a latency baseline, but it can select low-availability routes.
- Reliability-aware routing is useful when low-availability shortcuts distort the latency-only path choice.
- Effective latency is the thesis-facing comparison metric because it penalizes unreliable routes without claiming a full physical-layer ARQ model.
- Raw latency penalty should be reported alongside availability gain, otherwise the result is incomplete.

## Scope note

These results support a graph-level LEO routing study. They do not reproduce Wang et al. stochastic geometry, coverage probability, or exact ARQ delay derivations.
