# Study of routing in LEO networks

Reproducible MATLAB project for routing experiments in generated LEO satellite networks.

## Requirements

- MATLAB R2023a or newer.
- Previously validated with MATLAB R2025b.

The R2023a minimum is driven by `max(..., 'omitmissing')` in the Hypatia
forwarding-state comparison. The code also uses `readlines` (R2020b),
`exportgraphics` (R2020a), `arguments` blocks, `groupsummary`, `graph`, and
`shortestpath`. The recorded validation was performed with R2025b.

## Research Focus

The central evaluation question is:

> How do routing strategies in generated LEO satellite networks trade latency, reliability, and route stability under dynamic topology?

## Active Routing Comparison

- Shortest path baseline
- Reliability-aware weighted shortest path
- Stability-aware hysteresis variant (evaluated in a separate ablation)

## Primary Metrics

- Latency
- Route availability / reliability
- Availability-adjusted effective latency
- Route changes over time

## Quick Start

Open the repository root (the folder containing `RunFullThesisStudy.m`) as the
current folder in MATLAB, then reproduce the
MATLAB experiments and the bundled Hypatia ECDF analysis with:

```matlab
RunFullThesisStudy
```

This runs the 81-case main experiment, both 405-case robustness sweeps, the
243-case time-horizon sensitivity sweep, the 81-case controlled
constellation-size study, the 20-case topology-only ablation, the 216-case
reliability-stress ablation, the 675-case stability-aware hysteresis ablation,
the analysis figures and notes, the MAT summaries, and the independent
Hypatia validation artifacts.

Forwarding-state reconstruction and fresh Hypatia generation require the
external data described in `reproducibility/hypatia/README.md` and run separately.
The individual entry points remain available when only one stage is needed.

Run the smoke experiment:

```matlab
RunLEORoutingStudy
```

Run the experiment matrix:

```matlab
RunExperimentSuite
```

Run seed-sensitivity robustness checks:

```matlab
RunRobustnessSuite
```

The script uses its own `seedMatrix` with seeds `[11 23 42 77 101]`. Set `seedMatrix` explicitly before execution only when a custom robustness sweep is required.

Run the time-horizon sensitivity study:

```matlab
RunTimeHorizonSensitivity
```

This repeats the 81-case main matrix for `12`, `50`, and `100` time steps and
writes `outputs/time_horizon_sensitivity_results.csv` and the corresponding MAT
artifact. Route stability is compared through changes per available transition.

Run the controlled constellation-size study:

```matlab
RunControlledConstellationSensitivity
```

This uses topology-relative source-destination endpoints `(1,13)`, `(1,19)`,
and `(1,31)` for the `4x8`, `6x12`, and `8x20` constellations. The fixed
numeric pair `(1,16)` in the main matrix is not used to isolate size effects.

Run the topology-only route-variability ablation:

```matlab
RunTopologyOnlyAblation
```

This keeps each physical edge's latency and availability fixed across time,
varies only contact-window activation, and includes a static full-contact
control.

Run the reliability-stress ablation:

```matlab
RunReliabilityStressAblation
```

This compares 189 stressed cases, spanning risky-shortcut availabilities from
`0.20` to `0.90`, with 27 matched no-stress controls. It records risky-path
usage at snapshot level and identifies where the mean effective-latency result
changes sign.

Validate the published Hypatia route- and RTT-variability results:

```matlab
RunHypatiaValidation
```

This independently parses the bundled official ECDF data for Kuiper K1,
Starlink S1, and Telesat T1, checks all 4,950 ground-station pairs per
constellation, recomputes the reported distribution statistics, and writes a
summary CSV plus a two-panel ECDF figure under
`outputs/hypatia_validation/`. Provenance, source hashes, the Python
cross-check, and fresh `satgenpy` instructions are documented in
`reproducibility/hypatia/README.md`.

Run the stability-aware hysteresis ablation:

```matlab
RunStabilityAwareAblation
```

This compares the per-snapshot reliability-aware optimum with a route-persistent
variant over 675 matched cases and 100 snapshots per case. It varies five
hysteresis tolerances, five seeds, three route pairs, three contact duty
cycles, and three reliability weights. The output reports route-change
reduction together with latency, availability, and effective-latency cost.

Analyze generated results:

```matlab
AnalyzeExperimentResults
```

The analysis writes `outputs/results_notes.md`, six PNG figures under
`outputs/figures`, and `outputs/analysis_summary.mat`. The summary includes the
descriptive mean, standard deviation, observed range and outcome counts,
Pearson correlations with and without zero-tradeoff ties, controlled
constellation-size sensitivity, topology-only ablation, route-change
comparison, robustness summaries, time-horizon sensitivity, and the
reliability-stress/no-stress comparison.

Run tests:

```matlab
run('tests/RunAllTests.m')
```

Experiment matrices are validated before execution. Invalid ranges, ambiguous field
names, invalid route pairs, and non-integer seeds or time-step counts are rejected
instead of being silently clamped.


## Thesis and authorship

Author: Christos Vasileiou (Χρίστος Βασιλείου).
Diploma thesis: Study of routing in low Earth orbit satellite networks,
Department of Electrical and Computer Engineering, Democritus University of Thrace.
Supervisor: Theodoros Kaifas.

The MATLAB implementation, experiment scripts, tests, and independent analysis
utilities in this project accompany the diploma thesis.

## Upstream work and data provenance

Hypatia is the work of its original authors. This project uses the published
Hypatia results and external Hypatia software as described in
`reproducibility/hypatia/README.md`. Files under `official_data` and
`official_figures` are upstream reference data and figures, not original
measurements or figures authored by the thesis student. The upstream Hypatia
source tree and large release archive are not bundled here.

Generated MATLAB `.mat` files are omitted; the scripts regenerate them.
The original source files retain their contents.
