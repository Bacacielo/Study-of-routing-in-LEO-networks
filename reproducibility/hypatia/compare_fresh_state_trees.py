#!/usr/bin/env python3
"""Verify that fresh Hypatia inputs and dynamic states equal release files."""

from __future__ import annotations

import argparse
import hashlib
import json
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


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def manifest_hash(records: list[tuple[str, int, str]]) -> str:
    digest = hashlib.sha256()
    for relative_path, size, file_hash in records:
        digest.update(
            f"{relative_path}\0{size}\0{file_hash}\n".encode("utf-8")
        )
    return digest.hexdigest()


def compare_network(fresh: Path, released: Path) -> dict[str, Any]:
    fresh_files = sorted(
        path for path in fresh.rglob("*") if path.is_file()
    )
    fresh_records: list[tuple[str, int, str]] = []
    released_records: list[tuple[str, int, str]] = []
    missing: list[str] = []
    mismatched: list[str] = []
    fstate_count = 0
    bandwidth_count = 0

    for fresh_path in fresh_files:
        relative = fresh_path.relative_to(fresh).as_posix()
        if relative.startswith(
            "dynamic_state_100ms_for_200s/fstate_"
        ):
            fstate_count += 1
        elif relative.startswith(
            "dynamic_state_100ms_for_200s/gsl_if_bandwidth_"
        ):
            bandwidth_count += 1

        fresh_size = fresh_path.stat().st_size
        fresh_hash = sha256(fresh_path)
        fresh_records.append((relative, fresh_size, fresh_hash))
        released_path = released / relative
        if not released_path.is_file():
            missing.append(relative)
            continue
        released_size = released_path.stat().st_size
        released_hash = sha256(released_path)
        released_records.append((relative, released_size, released_hash))
        if fresh_size != released_size or fresh_hash != released_hash:
            mismatched.append(relative)

    exact = (
        len(fresh_files) == 4005
        and fstate_count == 2000
        and bandwidth_count == 2000
        and not missing
        and not mismatched
        and len(released_records) == len(fresh_records)
    )
    return {
        "fresh_directory": str(fresh),
        "released_directory": str(released),
        "fresh_file_count": len(fresh_files),
        "fstate_file_count": fstate_count,
        "bandwidth_file_count": bandwidth_count,
        "other_input_file_count": (
            len(fresh_files) - fstate_count - bandwidth_count
        ),
        "missing_from_release_count": len(missing),
        "content_mismatch_count": len(mismatched),
        "missing_from_release": missing,
        "content_mismatches": mismatched,
        "fresh_subset_manifest_sha256": manifest_hash(fresh_records),
        "released_subset_manifest_sha256": manifest_hash(released_records),
        "all_fresh_files_match_release_exactly": exact,
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--fresh-root",
        type=Path,
        required=True,
        help="Fresh Hypatia satellite_networks_state/gen_data directory.",
    )
    parser.add_argument(
        "--release-root",
        type=Path,
        required=True,
        help="Released Hypatia satellite_networks_state/gen_data directory.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parent
        / "fresh_state_tree_comparison.json",
        help="JSON report path.",
    )
    args = parser.parse_args()

    report: dict[str, Any] = {
        "method": (
            "SHA-256 comparison of every file produced in each focused "
            "fresh network directory against the same relative release file"
        ),
        "networks": {},
    }
    all_exact = True
    for key, network_name in NETWORKS.items():
        comparison = compare_network(
            args.fresh_root / network_name,
            args.release_root / network_name,
        )
        report["networks"][key] = comparison
        all_exact &= bool(
            comparison["all_fresh_files_match_release_exactly"]
        )

    report["total_fresh_files"] = sum(
        int(item["fresh_file_count"])
        for item in report["networks"].values()
    )
    report["total_fstate_files"] = sum(
        int(item["fstate_file_count"])
        for item in report["networks"].values()
    )
    report["total_bandwidth_files"] = sum(
        int(item["bandwidth_file_count"])
        for item in report["networks"].values()
    )
    report["all_networks_exact"] = all_exact
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        json.dumps(report, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )

    print(f"Comparison report: {args.output.resolve()}")
    print(f"Fresh files checked: {report['total_fresh_files']}")
    print(f"All three network trees exact: {all_exact}")
    return 0 if all_exact else 1


if __name__ == "__main__":
    raise SystemExit(main())
