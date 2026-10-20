# Phase 0 Baseline

Recorded on 2026-07-29 before adding the Hypatia reproduction pipeline.

## Repository state

- Branch: `master`
- Git HEAD: `2280718c3e4623f0a9d4e68a50e6e8759f72e640`
- The worktree already contained modified and untracked thesis files.
- No pre-existing user changes were reset, staged, overwritten, or removed.

## MATLAB baseline

- MATLAB: R2025b (`25.2.0.2998904`)
- Test entry point: `tests/RunAllTests.m`
- Result: 63 passed, 0 failed, 0 incomplete
- MATLAB Code Analyzer: 35 `.m` files checked, 0 issues

The tests write their delivery artifacts into isolated temporary directories.
The existing `outputs/` directory was not replaced during this audit.

## Thesis artifacts

| Artifact | SHA-256 |
|---|---|
| `docs/LEO_Routing_Thesis_HMMY_DUTH.docx` | `f529937f1c29cc857db222f3614b311a862ba112f805ebf82f53662e112d3730` |
| `docs/THESIS_DEFENSE_PREPARATION_EL.md` | `58b767cd16874305f8d6226cfe3f3562efd5f942f00fa3ea1a44190b7487b2f8` |
| `docs/THESIS_MANUSCRIPT_EL.md` | `f65e61e33cfd07db9ce45ca456a2f268461abff87759ba9ddc3d540f973a42df` |
| `outputs/reliability_stress_ablation_results.csv` | `6f8c6ad153eedf1847518a42cc9c17796b18fe0e7433d74539e73175591fd958` |
| `outputs/analysis_summary.mat` | `eec9939eee9a0c1212c7703ef32d75ce8221f24d1e244ca7e5de7742d7dd3676` |

## Document render baseline

- `LEO_Routing_Thesis_HMMY_DUTH.docx` rendered to 63 pages through the
  repository's read-only Microsoft Word renderer.
- Contact-sheet inspection found no visible clipping, overlap, or broken
  figures/tables.
- Full-resolution checks included the cover, the reliability-stress result,
  bibliography, and final limitations page.
- LibreOffice was not available to the bundled renderer, so Microsoft Word was
  used as the documented fallback.

This is a preservation checkpoint, not a claim that the manuscript content is
final. The Hypatia reproduction and the new routing experiments have not yet
been incorporated into the thesis document.
