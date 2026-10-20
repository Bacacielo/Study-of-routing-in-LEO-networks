#!/usr/bin/env bash

# Continue the focused Hypatia fresh-generation sequence after an already
# running Kuiper K1 workload. Starlink S1 and Telesat T1 are run serially so
# that the three CPU-heavy jobs never overlap.
#
# Usage:
#   run_remaining_fresh_sequence.sh \
#     HYPATIA_ROOT VENV_ROOT HELPER_SCRIPT THREADS LOG_DIRECTORY

set -euo pipefail

if [[ "$#" -ne 5 ]]; then
    echo "Usage: $0 HYPATIA_ROOT VENV_ROOT HELPER_SCRIPT THREADS LOG_DIRECTORY" >&2
    exit 2
fi

hypatia_root="$1"
venv_root="$2"
helper_script="$3"
threads="$4"
log_directory="$5"

mkdir -p "${log_directory}"

echo "Waiting for the running Kuiper K1 workload..."
while pgrep -f "[p]ython main_kuiper_630.py 200 100 " >/dev/null; do
    sleep 30
done

echo "Kuiper process ended at $(date --iso-8601=seconds)."

for workload_id in 7 10; do
    log_path="${log_directory}/workload_${workload_id}.log"
    echo "Starting workload ${workload_id} at $(date --iso-8601=seconds)."
    bash "${helper_script}" \
        "${hypatia_root}" \
        "${venv_root}" \
        "${workload_id}" \
        "${threads}" \
        >"${log_path}" 2>&1
    echo "Completed workload ${workload_id} at $(date --iso-8601=seconds)."
done

echo "Fresh Hypatia sequence completed at $(date --iso-8601=seconds)."
