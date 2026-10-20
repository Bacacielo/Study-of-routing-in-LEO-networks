# Independent Forwarding-State Validation

Release-state check recorded on 2026-07-29 and fresh-state check recorded on
2026-07-30 using MATLAB R2025b.

## Question

Do the published path-change ECDF values follow from the released Hypatia
forwarding states, or are they only being accepted from an already processed
analysis file?

## Method

`src/ThesisHypatiaStateAnalyzer.m` reads the complete released
`dynamic_state_100ms_for_200s` time series for each constellation. It:

1. checks that all 2,000 expected `fstate_<time>.txt` files are present;
2. initializes the complete forwarding table from the first snapshot;
3. applies every subsequent file as a delta update;
4. follows the forwarding decisions for each of the 4,950 unique
   ground-station pairs;
5. compares the exact node sequence with the preceding snapshot; and
6. counts changes before constructing a new empirical distribution.

The MATLAB calculation does not read Hypatia's ready-made path-analysis ECDF
while reconstructing the routes. That file is used only after calculation as
the comparison target.

## Results

| Constellation | Satellites | Pairs | Median changes | Mean changes | p90 | p95 | Fraction with at least 7 | Exact ECDF mismatches |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Kuiper K1 | 1,156 | 4,950 | 4 | 4.3853 | 7 | 8 | 11.535% | 0 |
| Starlink S1 | 1,584 | 4,950 | 4 | 4.5051 | 7 | 7 | 11.051% | 0 |
| Telesat T1 | 351 | 4,950 | 2 | 1.9800 | 4 | 4 | 0.606% | 0 |

All 14,850 independently reconstructed pair values match the official ECDFs
exactly. The calculation was then repeated on newly generated state from the
pinned Hypatia source and environment. The fresh run again processed 2,000
snapshots per constellation and produced the same exact `14,850/14,850`
agreement, with zero mismatches in every constellation. Thus the result is not
limited to forwarding-state files distributed in the release archive.

The Hypatia name `kuiper_630` refers to the approximately 630 km orbital
altitude. It is not the satellite count; the modeled shell contains
`34 x 34 = 1,156` satellites.

## Artifacts

- `outputs/hypatia_state_validation/hypatia_fstate_validation_all.csv`
- one 4,950-row pair table per constellation under
  `outputs/hypatia_state_validation/<constellation>/`
- `outputs/hypatia_fresh_validation/hypatia_fresh_fstate_validation_all.csv`
- one fresh 4,950-row pair table per constellation under
  `outputs/hypatia_fresh_validation/<constellation>/`
- `RunFreshHypatiaValidation.m`
- `tests/TestThesisHypatiaStateAnalyzer.m`
- `tests/fixtures/hypatia_state_small/`

## Boundary of this check

This check independently verifies path reconstruction and route-change
counting from forwarding state. RTT-range values have been independently
parsed and summarized from the official raw ECDF inputs. Fresh generation
additionally produced `12,015/12,015` files that are byte-identical to the
released static and dynamic inputs. A separately completed fresh
orbital-distance recomputation for every constellation is not claimed; the
precise fresh-generation boundary is recorded in `FRESH_GENERATION.md`.
