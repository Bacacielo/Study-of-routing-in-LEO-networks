# Hypatia Paper Reproduction

This folder records the focused reproduction of Figures 7(b), 8(a), and 10
from:

> S. Kassing, D. Bhattacherjee, A. B. Águas, J. E. Saethre, and A. Singla,
> "Exploring the Internet from Space with Hypatia," IMC 2020.

## Pinned provenance

- Hypatia commit: `0ac531c313eba2335f6344b46347140c3a0d4230`
- Release tag: `v1`
- Archive: `hypatia_paper_temp_data.tar.gz`
- Archive size: `500557372` bytes
- Published SHA-256:
  `18d761a28706723b57772e0636fbc40b7d57161f4c54069eede0c8ae740cbe2d`

The release archive itself is intentionally not stored in this repository.

## Verified environment

- Ubuntu 24.04.4 LTS under WSL2
- Python 3.12.3
- NumPy 1.26.4
- Astropy 6.1.7
- NetworkX 2.8.8
- SGP4 2.24
- Matplotlib 3.9.4
- Statsmodels 0.14.4
- Cartopy 0.24.1
- `exputil` 1.6, upstream commit
  `014750099016c725346d5a164e738c93c8a42224`
- `networkload` 1.3, upstream commit
  `3531c28466a8461cdd0cc1708426389305cd48f8`
- gnuplot 6.0 patchlevel 0
- Poppler 24.02.0

## Official extraction and plotting

After placing the verified archive in `<hypatia>/paper/`:

```bash
cd <hypatia>/paper
printf 'yes\n' | <venv>/bin/python extract_temp_data.py

cd figures/constellation_comparison/general_ecdfs
gnuplot plot_ecdf_max_minus_min_rtt.plt
gnuplot plot_ecdf_num_path_changes.plt

cd ../../traffic_matrix_unused_bandwidth
gnuplot plot_specific_tm_time_vs_available_bandwidth_over_path.plt
```

The full official `plot_all.py` also generated the three target plots, but
later stopped at the unrelated `two_compete` plot because the v1 release does
not contain its referenced input file. The three target `.plt` files were
therefore rerun individually and completed successfully.

## Independent numeric verification

Run:

```powershell
python reproducibility/hypatia/analyze_official_data.py `
  <hypatia-paper-directory> `
  --verify-paper-anchors `
  --output reproducibility/hypatia/official_results.json
```

The analyzer reads the same source files used by the official plotting scripts,
checks their ECDF structure, calculates the headline statistics, records input
hashes, and fails if the publication anchors are not reproduced.

## Independent MATLAB verification

The six official ECDF source files used for Figures 7(b) and 8(a) are stored
under `official_data/`. They contain all `4,950` unique pairs among the 100
ground stations for each constellation, not only the published medians.
Their SHA-256 hashes are recorded in `official_results.json`.

Run the independent MATLAB parser and validator with:

```matlab
RunHypatiaValidation
```

The MATLAB implementation independently checks the Hypatia sentinel row, ECDF
ordering, probability increments and final probability. It then recomputes
the pair count, mean, median, nearest-rank p90/p95, fraction with at least
seven path changes, and RTT range statistics. It does not call the Python
analyzer.

Generated artifacts:

- `outputs/hypatia_validation/hypatia_validation_summary.csv`
- `outputs/hypatia_validation/hypatia_validation_ecdfs.png`

The MATLAB and Python summaries are cross-checked by
`tests/TestThesisHypatiaValidation.m`.

The deeper forwarding-state reconstruction and its exact three-constellation
results are recorded in `FSTATE_VALIDATION.md`.

## Fresh `satgenpy` generation

The Python environment is pinned in
`requirements-satgenpy-python312.txt`. The helper below runs exactly one
official workload while keeping its large generated state outside the
repository:

```bash
bash run_hypatia_workload.sh \
  <hypatia-source-root> <venv-root> <workload-id> <threads>
```

The focused 100-ms workloads are IDs `4` (Kuiper K1), `7` (Starlink S1), and
`10` (Telesat T1). These are the only fresh state-generation workloads needed
for the route-change and RTT-variation comparison.

When Kuiper ID `4` is already running, the optional helper
`run_remaining_fresh_sequence.sh` waits for that process to end and then runs
IDs `7` and `10` serially. Serial execution is intentional because each
official generator already uses multiple worker processes.

After a workload has generated its `dynamic_state_100ms_for_200s` directory,
MATLAB can reconstruct every route from the incremental forwarding-state
updates and compare all 4,950 route-change counts with the official ECDF:

```matlab
RunHypatiaStateValidation( ...
    "<generated-satellite-network-directory>", ...
    "kuiper_k1")
```

Use `starlink_s1` or `telesat_t1` for the other two workloads. This validation
does not read the ready-made path analysis: it maintains the forwarding table
from `fstate_<time>.txt`, follows each source-destination route at all 2,000
snapshots, and counts exact path changes. A compact synthetic delta-state
fixture tests this reconstruction in
`tests/TestThesisHypatiaStateAnalyzer.m`.

For a generation root that contains all three focused networks, run the
combined check with:

```matlab
RunFreshHypatiaValidation("<hypatia-gen-data-directory>")
```

The fresh run completed on 2026-07-30. It checked 6,000 newly generated
snapshots and independently reconstructed 14,850 ground-station-pair values.
All `14,850/14,850` route-change counts matched the official ECDFs exactly.
The combined machine-readable summary is
`outputs/hypatia_fresh_validation/hypatia_fresh_fstate_validation_all.csv`.

Every fresh file was also compared by SHA-256 with the file at the same
relative path in the released state tree:

```bash
python compare_fresh_state_trees.py \
  --fresh-root <fresh-gen-data-directory> \
  --release-root <released-gen-data-directory>
```

The comparison covered `12,015` files: `2,000` forwarding-state files,
`2,000` bandwidth-state files, and five static/input files for each
constellation. All `12,015/12,015` matched exactly, with zero missing files and
zero content mismatches. The full method, per-constellation manifest hashes,
generator runtimes, and interpretation boundary are in
`FRESH_GENERATION.md` and `fresh_state_tree_comparison.json`.

The official path and RTT post-analysis can be rerun serially on those fresh
states with:

```bash
bash run_fresh_post_analysis.sh \
  <hypatia-source-root> <venv-root> [output-directory]
```

The helper refuses to overwrite an existing output directory and stores a
separate timing log for each of the six analyses. Compare the two target ECDFs
per constellation with the bundled v1 reference files using:

```bash
python compare_fresh_post_analysis.py \
  --fresh-data-dir <output-directory>
```

This optional post-analysis is computationally expensive and is not required
to establish fresh state generation when the complete static and dynamic input
trees have already matched the release byte for byte. One Kuiper path run was
completed as a spot check and produced a byte-identical route-change ECDF. A
separately completed fresh RTT post-analysis for all three constellations is
not claimed.

## Important Figure 10 detail

Figure 10 is drawn from utilization values averaged to 1-second points.
However, the reported `31%` dynamic and `11%` static statistics are calculated
by the official analysis script from the original 100-ms intervals before that
averaging:

- moving: `599 / 1902 = 31.49%`
- static: `218 / 2000 = 10.90%`

Calculating the percentages directly from the plotted 1-second averages gives
different values and is not the method used in the paper.

## Outputs

- `official_results.json`: machine-readable statistics and source hashes
- `official_figures/fig7b.png`: regenerated RTT-variation ECDF
- `official_figures/fig8a.png`: regenerated path-change ECDF
- `official_figures/fig10.png`: regenerated unused-bandwidth trace

The official figures are release-data reproductions. Fresh `satgenpy` state
generation is kept separate so that downloaded reference data and newly
generated results cannot be confused.
