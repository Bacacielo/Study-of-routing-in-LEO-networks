#!/usr/bin/env python3
"""Compare freshly computed Hypatia ECDFs with the official v1 release data."""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
from pathlib import Path
from typing import Any


NETWORKS = {
    "kuiper_k1": (
        "kuiper_630_isls_plus_grid_ground_stations_top_100_"
        "algorithm_free_one_only_over_isls"
    ),
    "starlink_s1": (
        "starlink_550_isls_plus_grid_ground_stations_top_100_"
        "algorithm_free_one_only_over_isls"
    ),
    "telesat_t1": (
        "telesat_1015_isls_plus_grid_ground_stations_top_100_"
        "algorithm_free_one_only_over_isls"
    ),
}

METRICS = {
    "path_changes": (
        "path",
        "ecdf_pairs_num_path_changes.txt",
    ),
    "rtt_range_ns": (
        "rtt",
        "ecdf_pairs_max_minus_min_rtt_ns.txt",
    ),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_rows(path: Path) -> list[tuple[float, float]]:
    rows: list[tuple[float, float]] = []
    with path.open("r", encoding="utf-8", newline="") as handle:
        for line_number, row in enumerate(csv.reader(handle), start=1):
            if len(row) != 2:
                raise ValueError(
                    f"Malformed ECDF row {line_number} in {path}: {row!r}"
                )
            rows.append((float(row[0]), float(row[1])))
    if not rows:
        raise ValueError(f"No ECDF rows found in {path}")
    return rows


def numeric_delta(left: float, right: float) -> float:
    if left == right:
        return 0.0
    if math.isnan(left) and math.isnan(right):
        return 0.0
    return abs(left - right)


def compare_files(generated: Path, official: Path) -> dict[str, Any]:
    generated_rows = read_rows(generated)
    official_rows = read_rows(official)
    paired_count = min(len(generated_rows), len(official_rows))
    value_deltas = [
        numeric_delta(generated_rows[index][0], official_rows[index][0])
        for index in range(paired_count)
    ]
    probability_deltas = [
        numeric_delta(generated_rows[index][1], official_rows[index][1])
        for index in range(paired_count)
    ]
    numeric_exact = (
        len(generated_rows) == len(official_rows)
        and all(delta == 0.0 for delta in value_deltas)
        and all(delta == 0.0 for delta in probability_deltas)
    )
    generated_hash = sha256(generated)
    official_hash = sha256(official)
    return {
        "generated_file": str(generated),
        "official_file": str(official),
        "generated_rows": len(generated_rows),
        "official_rows": len(official_rows),
        "max_absolute_value_difference": max(value_deltas, default=math.inf),
        "max_absolute_probability_difference": max(
            probability_deltas, default=math.inf
        ),
        "numeric_exact_match": numeric_exact,
        "generated_sha256": generated_hash,
        "official_sha256": official_hash,
        "byte_exact_match": generated_hash == official_hash,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fresh-data-dir",
        type=Path,
        required=True,
        help="Root produced by run_fresh_post_analysis.sh.",
    )
    parser.add_argument(
        "--official-data-dir",
        type=Path,
        default=Path(__file__).resolve().parent / "official_data",
        help="Directory containing the six official ECDF files.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent
        / "fresh_post_analysis_comparison.json",
        help="JSON report path.",
    )
    args = parser.parse_args()

    report: dict[str, Any] = {
        "experiment": {
            "duration_seconds": 200,
            "snapshot_interval_ms": 100,
            "ground_stations": 100,
            "ground_station_pairs": 4950,
        },
        "comparisons": {},
    }
    all_numeric_exact = True
    all_byte_exact = True

    for key, network_name in NETWORKS.items():
        report["comparisons"][key] = {}
        for metric, (analysis, filename) in METRICS.items():
            generated = (
                args.fresh_data_dir
                / network_name
                / "100ms_for_200s"
                / analysis
                / "data"
                / filename
            )
            official = args.official_data_dir / key / filename
            comparison = compare_files(generated, official)
            report["comparisons"][key][metric] = comparison
            all_numeric_exact &= bool(comparison["numeric_exact_match"])
            all_byte_exact &= bool(comparison["byte_exact_match"])

    report["all_numeric_exact"] = all_numeric_exact
    report["all_byte_exact"] = all_byte_exact
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print(f"Comparison report: {args.output.resolve()}")
    print(f"All six ECDFs numerically exact: {all_numeric_exact}")
    print(f"All six ECDFs byte-for-byte exact: {all_byte_exact}")
    return 0 if all_numeric_exact else 1


if __name__ == "__main__":
    raise SystemExit(main())
