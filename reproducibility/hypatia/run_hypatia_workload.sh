#!/usr/bin/env bash

# Run one official Hypatia satellite-state workload with a pinned Python
# environment. The generated data stay outside this repository.
#
# Usage:
#   run_hypatia_workload.sh HYPATIA_ROOT VENV_ROOT WORKLOAD_ID THREADS

set -euo pipefail

if [[ "$#" -ne 4 ]]; then
    echo "Usage: $0 HYPATIA_ROOT VENV_ROOT WORKLOAD_ID THREADS" >&2
    exit 2
fi

hypatia_root="$1"
venv_root="$2"
workload_id="$3"
threads="$4"

if [[ ! -f "${hypatia_root}/paper/satellite_networks_state/generate_for_paper.sh" ]]; then
    echo "Hypatia source tree not found: ${hypatia_root}" >&2
    exit 2
fi

if [[ ! -f "${venv_root}/bin/activate" ]]; then
    echo "Python virtual environment not found: ${venv_root}" >&2
    exit 2
fi

if ! [[ "${workload_id}" =~ ^[0-9]+$ ]] || (( workload_id < 0 || workload_id > 14 )); then
    echo "WORKLOAD_ID must be an integer from 0 through 14." >&2
    exit 2
fi

if ! [[ "${threads}" =~ ^[0-9]+$ ]] || (( threads < 1 || threads > 128 )); then
    echo "THREADS must be an integer from 1 through 128." >&2
    exit 2
fi

# shellcheck disable=SC1090
source "${venv_root}/bin/activate"
cd "${hypatia_root}/paper/satellite_networks_state"

exec /usr/bin/time -v bash generate_for_paper.sh "${workload_id}" "${threads}"
