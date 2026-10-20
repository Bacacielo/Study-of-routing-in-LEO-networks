#!/usr/bin/env bash

# Run the official Hypatia path and RTT post-analysis on freshly generated
# dynamic state. The six analyses are deliberately serial to keep resource
# usage predictable and to preserve a separate timing log for every run.
#
# Usage:
#   run_fresh_post_analysis.sh HYPATIA_ROOT VENV_ROOT [OUTPUT_DIRECTORY]

set -euo pipefail

if [[ "$#" -lt 2 || "$#" -gt 3 ]]; then
    echo "Usage: $0 HYPATIA_ROOT VENV_ROOT [OUTPUT_DIRECTORY]" >&2
    exit 2
fi

hypatia_root="$(cd "$1" && pwd)"
venv_root="$(cd "$2" && pwd)"
output_directory="${3:-${hypatia_root}/paper/satgenpy_analysis/fresh_data}"

if [[ -e "${output_directory}" ]]; then
    echo "Refusing to overwrite existing output directory: ${output_directory}" >&2
    exit 3
fi

mkdir -p "${output_directory}/logs"
output_directory="$(cd "${output_directory}" && pwd)"
source "${venv_root}/bin/activate"
cd "${hypatia_root}/satgenpy"

network_names=(
    "kuiper_630_isls_plus_grid_ground_stations_top_100_algorithm_free_one_only_over_isls"
    "starlink_550_isls_plus_grid_ground_stations_top_100_algorithm_free_one_only_over_isls"
    "telesat_1015_isls_plus_grid_ground_stations_top_100_algorithm_free_one_only_over_isls"
)

for network_name in "${network_names[@]}"; do
    network_directory="../paper/satellite_networks_state/gen_data/${network_name}"
    if [[ ! -d "${network_directory}/dynamic_state_100ms_for_200s" ]]; then
        echo "Missing generated state: ${network_directory}/dynamic_state_100ms_for_200s" >&2
        exit 4
    fi

    for analysis in path rtt; do
        module="satgen.post_analysis.main_analyze_${analysis}"
        log_path="${output_directory}/logs/${network_name}_${analysis}.log"
        echo "Starting ${network_name} ${analysis} at $(date --iso-8601=seconds)."
        /usr/bin/time -v \
            python -m "${module}" \
            "${output_directory}" \
            "${network_directory}" \
            100 \
            200 \
            >"${log_path}" 2>&1
        echo "Completed ${network_name} ${analysis} at $(date --iso-8601=seconds)."
    done
done

echo "Fresh Hypatia post-analysis completed at $(date --iso-8601=seconds)."
