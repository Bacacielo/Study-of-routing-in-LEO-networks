#!/usr/bin/env python3
"""Summarize and verify the official Hypatia IMC 2020 release data.

The script intentionally uses only the Python standard library. It reads the
same ECDF and traffic-utilization files used by the official gnuplot scripts.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
import statistics
from pathlib import Path
from typing import Any


HYPATIA_COMMIT = "0ac531c313eba2335f6344b46347140c3a0d4230"
RELEASE_ARCHIVE_SHA256 = (
    "18d761a28706723b57772e0636fbc40b7d57161f4c54069eede0c8ae740cbe2d"
)

CONSTELLATIONS = {
    "telesat_t1": (
        "Telesat T1",
        "telesat_1015_isls_plus_grid_ground_stations_top_100_"
        "algorithm_free_one_only_over_isls",
    ),
    "kuiper_k1": (
        "Kuiper K1",
        "kuiper_630_isls_plus_grid_ground_stations_top_100_"
        "algorithm_free_one_only_over_isls",
    ),
    "starlink_s1": (
        "Starlink S1",
        "starlink_550_isls_plus_grid_ground_stations_top_100_"
        "algorithm_free_one_only_over_isls",
    ),
}


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def read_ecdf_values(path: Path) -> list[float]:
    values: list[float] = []
    probabilities: list[float] = []
    with path.open("r", encoding="utf-8", newline="") as handle:
        for row in csv.reader(handle):
            if len(row) != 2:
                raise ValueError(f"Malformed ECDF row in {path}: {row!r}")
            value = float(row[0])
            probability = float(row[1])
            if math.isfinite(value):
                values.append(value)
                probabilities.append(probability)

    if not values:
        raise ValueError(f"No finite ECDF values found in {path}")
    if any(a > b for a, b in zip(values, values[1:])):
        raise ValueError(f"ECDF values are not sorted in {path}")
    if any(a > b for a, b in zip(probabilities, probabilities[1:])):
        raise ValueError(f"ECDF probabilities are not monotonic in {path}")
    if not math.isclose(probabilities[-1], 1.0, abs_tol=1e-12):
        raise ValueError(f"ECDF does not terminate at one in {path}")
    return values


def nearest_rank(values: list[float], probability: float) -> float:
    if not 0.0 < probability <= 1.0:
        raise ValueError("Nearest-rank probability must be in (0, 1].")
    index = math.ceil(probability * len(values)) - 1
    return values[index]


def summarize_values(values: list[float]) -> dict[str, float | int]:
    return {
        "count": len(values),
        "median": statistics.median(values),
        "mean": statistics.fmean(values),
        "p90_nearest_rank": nearest_rank(values, 0.90),
        "p95_nearest_rank": nearest_rank(values, 0.95),
        "minimum": values[0],
        "maximum": values[-1],
    }


def parse_utilization_information(path: Path) -> dict[str, float | int]:
    text = path.read_text(encoding="utf-8")
    patterns = {
        "total_intervals": r"Total intervals\.*\s+(\d+)",
        "intervals_with_path": r"Intervals with a path\.*\s+(\d+)",
        "intervals_over_one_third_unused": (
            r"Intervals \(w/path\) with utilization <= 2/3\.*\s+(\d+)"
        ),
        "reported_percent_over_one_third_unused": (
            r"([0-9.]+)% of the intervals have at least 33% unused bandwidth"
        ),
    }
    result: dict[str, float | int] = {}
    for key, pattern in patterns.items():
        match = re.search(pattern, text)
        if match is None:
            raise ValueError(f"Could not parse {key} from {path}")
        result[key] = float(match.group(1)) if "percent" in key else int(match.group(1))

    denominator = int(result["intervals_with_path"])
    numerator = int(result["intervals_over_one_third_unused"])
    computed_percent = numerator / denominator * 100.0
    result["computed_percent_over_one_third_unused"] = computed_percent
    if not math.isclose(
        float(result["reported_percent_over_one_third_unused"]),
        computed_percent,
        abs_tol=0.005,
    ):
        raise ValueError(f"Reported and computed percentages differ in {path}")
    return result


def relative_file_record(paper_dir: Path, path: Path) -> dict[str, Any]:
    return {
        "path": path.relative_to(paper_dir).as_posix(),
        "bytes": path.stat().st_size,
        "sha256": sha256(path),
    }


def build_summary(paper_dir: Path) -> dict[str, Any]:
    satgen_data = paper_dir / "satgenpy_analysis" / "data"
    constellation_results: dict[str, Any] = {}
    source_files: list[dict[str, Any]] = []

    for key, (label, directory) in CONSTELLATIONS.items():
        scenario = satgen_data / directory / "100ms_for_200s"
        path_ecdf = scenario / "path" / "data" / "ecdf_pairs_num_path_changes.txt"
        rtt_ecdf = (
            scenario / "rtt" / "data" / "ecdf_pairs_max_minus_min_rtt_ns.txt"
        )
        path_changes = read_ecdf_values(path_ecdf)
        rtt_range_ms = [value / 1_000_000.0 for value in read_ecdf_values(rtt_ecdf)]
        path_summary = summarize_values(path_changes)
        path_summary["fraction_at_least_7"] = (
            sum(value >= 7 for value in path_changes) / len(path_changes)
        )
        constellation_results[key] = {
            "label": label,
            "path_changes": path_summary,
            "rtt_max_minus_min_ms": summarize_values(rtt_range_ms),
        }
        source_files.extend(
            [
                relative_file_record(paper_dir, path_ecdf),
                relative_file_record(paper_dir, rtt_ecdf),
            ]
        )

    traffic_data = paper_dir / "ns3_experiments" / "traffic_matrix" / "data"
    moving_dir = traffic_data / "run_specific_tm_pairing_kuiper_isls_moving"
    static_dir = traffic_data / "run_specific_tm_pairing_kuiper_isls_static"
    moving_info = moving_dir / "utilization_information_1174_to_1229.txt"
    static_info = static_dir / "utilization_information_1174_to_1229.txt"
    moving_plot_data = moving_dir / "pair_path_utilization_at_1s_1174_to_1229.txt"
    static_plot_data = static_dir / "pair_path_utilization_at_1s_1174_to_1229.txt"
    source_files.extend(
        [
            relative_file_record(paper_dir, moving_info),
            relative_file_record(paper_dir, static_info),
            relative_file_record(paper_dir, moving_plot_data),
            relative_file_record(paper_dir, static_plot_data),
        ]
    )

    figure_paths = {
        "figure_7b": (
            paper_dir
            / "figures"
            / "constellation_comparison"
            / "general_ecdfs"
            / "pdf"
            / "ecdf_max_minus_min_rtt.pdf"
        ),
        "figure_8a": (
            paper_dir
            / "figures"
            / "constellation_comparison"
            / "general_ecdfs"
            / "pdf"
            / "ecdf_num_path_changes.pdf"
        ),
        "figure_10": (
            paper_dir
            / "figures"
            / "traffic_matrix_unused_bandwidth"
            / "pdf"
            / "plot_specific_tm_time_vs_available_bandwidth_over_path.pdf"
        ),
    }

    return {
        "provenance": {
            "hypatia_commit": HYPATIA_COMMIT,
            "release_tag": "v1",
            "release_archive_bytes": 500_557_372,
            "release_archive_sha256": RELEASE_ARCHIVE_SHA256,
        },
        "experiment": {
            "duration_seconds": 200,
            "snapshot_interval_ms": 100,
            "ground_stations": 100,
            "unique_ground_station_pairs": 4_950,
        },
        "constellations": constellation_results,
        "figure_10": {
            "scenario": "Kuiper K1, Rio de Janeiro to St. Petersburg",
            "link_capacity_mbps": 10,
            "moving": parse_utilization_information(moving_info),
            "static": parse_utilization_information(static_info),
            "statistic_granularity_ms": 100,
            "plot_granularity_ms": 1_000,
            "note": (
                "The 31.49% and 10.90% statistics are computed from 100 ms "
                "intervals before the official plot data are averaged to 1 s."
            ),
        },
        "source_files": source_files,
        "regenerated_figures": {
            name: relative_file_record(paper_dir, path)
            for name, path in figure_paths.items()
        },
    }


def verify_paper_anchors(summary: dict[str, Any]) -> None:
    expected_medians = {
        "telesat_t1": 2,
        "kuiper_k1": 4,
        "starlink_s1": 4,
    }
    for key, expected in expected_medians.items():
        actual = summary["constellations"][key]["path_changes"]["median"]
        if actual != expected:
            raise AssertionError(
                f"{key} median path changes: expected {expected}, got {actual}"
            )
        count = summary["constellations"][key]["path_changes"]["count"]
        if count != 4_950:
            raise AssertionError(f"{key} pair count: expected 4950, got {count}")

    for key in ("kuiper_k1", "starlink_s1"):
        fraction = summary["constellations"][key]["path_changes"][
            "fraction_at_least_7"
        ]
        if fraction < 0.10:
            raise AssertionError(f"{key} fraction with >=7 path changes is {fraction}")

    starlink_rtt_median = summary["constellations"]["starlink_s1"][
        "rtt_max_minus_min_ms"
    ]["median"]
    if not 9.0 <= starlink_rtt_median <= 11.0:
        raise AssertionError(
            f"Starlink median RTT range is not approximately 10 ms: "
            f"{starlink_rtt_median}"
        )

    moving_percent = summary["figure_10"]["moving"][
        "computed_percent_over_one_third_unused"
    ]
    static_percent = summary["figure_10"]["static"][
        "computed_percent_over_one_third_unused"
    ]
    if round(moving_percent) != 31 or round(static_percent) != 11:
        raise AssertionError(
            "Figure 10 anchors do not round to 31% moving and 11% static: "
            f"{moving_percent:.2f}% and {static_percent:.2f}%"
        )


def print_summary(summary: dict[str, Any]) -> None:
    for result in summary["constellations"].values():
        path_changes = result["path_changes"]
        rtt_range = result["rtt_max_minus_min_ms"]
        print(
            f"{result['label']}: pairs={path_changes['count']}, "
            f"median_path_changes={path_changes['median']:.1f}, "
            f"fraction_ge_7={path_changes['fraction_at_least_7']:.4f}, "
            f"median_rtt_range_ms={rtt_range['median']:.4f}"
        )
    moving = summary["figure_10"]["moving"][
        "computed_percent_over_one_third_unused"
    ]
    static = summary["figure_10"]["static"][
        "computed_percent_over_one_third_unused"
    ]
    print(f"Figure 10: moving={moving:.2f}%, static={static:.2f}%")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "paper_dir",
        type=Path,
        help="Path to the extracted <hypatia>/paper directory.",
    )
    parser.add_argument("--output", type=Path, help="Optional JSON output path.")
    parser.add_argument(
        "--verify-paper-anchors",
        action="store_true",
        help="Fail if the published headline values are not reproduced.",
    )
    args = parser.parse_args()

    paper_dir = args.paper_dir.resolve()
    if not (paper_dir / "figures" / "README.md").is_file():
        raise FileNotFoundError(f"Not an extracted Hypatia paper directory: {paper_dir}")

    summary = build_summary(paper_dir)
    if args.verify_paper_anchors:
        verify_paper_anchors(summary)
    print_summary(summary)

    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(
            json.dumps(summary, indent=2, sort_keys=True) + "\n",
            encoding="utf-8",
        )
        print(f"Wrote {args.output}")


if __name__ == "__main__":
    main()
