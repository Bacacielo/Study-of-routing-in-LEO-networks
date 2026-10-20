# Fresh Hypatia State Generation

Recorded on 2026-07-30.

## Objective

The release-state reconstruction proves that the published route-change ECDF
follows from the distributed forwarding-state deltas. This additional check
asks a different question: can the three focused 100-ms workloads be generated
again from the pinned Hypatia source and environment?

## Pinned setup

- Hypatia v1 commit:
  `0ac531c313eba2335f6344b46347140c3a0d4230`
- Python environment specification:
  `requirements-satgenpy-python312.txt`
- Environment-file SHA-256:
  `E7D76CB1A99F9C6C841424A624A307680613B30B1CA7752FAA47B1DA24221D64`
- Workloads: ID `4` (Kuiper K1), ID `7` (Starlink S1), and ID `10`
  (Telesat T1)
- Dynamic-state interval and duration: `100 ms` for `200 s`

The three official generators were run serially. Every generator returned exit
status zero:

| Workload | Threads | Wall-clock time | Exit status |
|---|---:|---:|---:|
| Kuiper K1 | 16 | 3:03:01 | 0 |
| Starlink S1 | 16 | 6:00:34 | 0 |
| Telesat T1 | 16 | 1:10:47 | 0 |

## Byte-level result

`compare_fresh_state_trees.py` hashes every file produced in each focused
network directory and compares it with the file at the same relative path in
the released state tree.

| Workload | Fresh files | `fstate` files | Bandwidth files | Missing | Content mismatches | Exact |
|---|---:|---:|---:|---:|---:|---:|
| Kuiper K1 | 4,005 | 2,000 | 2,000 | 0 | 0 | yes |
| Starlink S1 | 4,005 | 2,000 | 2,000 | 0 | 0 | yes |
| Telesat T1 | 4,005 | 2,000 | 2,000 | 0 | 0 | yes |

All `12,015/12,015` fresh files are byte-identical to their released
counterparts. The matching subset-manifest SHA-256 values are:

- Kuiper K1:
  `41F420E646C8D460C0002CA875584142C9B22520FD62C40966B193C1546F6421`
- Starlink S1:
  `F127F31658ADC90ED17F0DED711D6ECF8680CB70A99EBD92D551EBFCD1CE95A7`
- Telesat T1:
  `C27088C230282DB9A6C7ADA4F9D26A5919420B3FBC99EE26E85AF226A3120DB8`

The five non-dynamic files per directory include the topology, TLE,
ground-station, and interface inputs needed by post-analysis. The exact tree
agreement therefore covers both the generated state and its associated static
inputs.

## Independent semantic result

`RunFreshHypatiaValidation.m` independently reconstructed every route from the
fresh delta states:

- `2,000` snapshots per constellation;
- `4,950` unique ground-station pairs per constellation;
- `14,850/14,850` route-change counts equal to the official ECDF values;
- zero ECDF mismatches for every constellation.

This duplicates the released-state semantic check on newly generated files
without reading the ready-made path ECDF during reconstruction.

## Post-analysis boundary

One official fresh post-analysis run was completed for the Kuiper path metric.
Its target route-change ECDF was byte-identical to the release file, with
SHA-256:

`139E77A077E511918180D211EE7B0B81213E04EF17F294121D2B5CC6717A84D9`

A full second pass of all path and RTT post-analysis jobs was not reported as
completed. The RTT job is much slower and was stopped after the complete
fresh-state comparison established that all static and dynamic inputs were
already byte-identical to the release inputs. Re-running deterministic
post-analysis on identical inputs would not add an independent state-generation
check. The thesis therefore reports:

1. full release-data reproduction of the selected path and RTT ECDFs;
2. exact fresh generation of all focused input/state trees; and
3. full independent route reconstruction from both released and fresh states.

It does not claim a separately completed fresh orbital-distance recomputation
for all three constellations.

## Artifacts

- `fresh_state_tree_comparison.json`
- `compare_fresh_state_trees.py`
- `RunFreshHypatiaValidation.m`
- `outputs/hypatia_fresh_validation/hypatia_fresh_fstate_validation_all.csv`
- `run_hypatia_workload.sh`
- `run_remaining_fresh_sequence.sh`
- optional expensive post-analysis helper: `run_fresh_post_analysis.sh`

## Interpretation limit

The result verifies reproducibility of three pinned Hypatia simulation
workloads. It is not a validation against measurements from operational
Starlink, Kuiper, or Telesat networks.
