#!/bin/bash
set -uo pipefail

check_required_env() {
  VAR_NAME=$1
  if [ -z "${!VAR_NAME:-}" ]; then
    echo "Error: Environment variable $VAR_NAME is required but not set (or empty)."
    exit 1
  else
    echo "Environment variable $VAR_NAME is set to: ${!VAR_NAME}"
  fi
}

# Required envs
check_required_env "ALGO"
check_required_env "POOL"
check_required_env "WALLET"

# Optional
WORKER="${WORKER:-}"
PASSWORD="${PASSWORD:-}"
CPU_MINING="${CPU_MINING:-false}"
EXTRA="${EXTRA:-}"

CMD=( ./SRBMiner-MULTI --algorithm "${ALGO}" --pool "${POOL}" --wallet "${WALLET}" )

if [ -n "$WORKER" ]; then
  CMD+=( --worker "${WORKER}" )
fi

if [ -n "$PASSWORD" ]; then
  CMD+=( --password "${PASSWORD}" )
fi

# GPU only unless asked otherwise: SRBMiner also mines on the CPU for any
# algorithm that supports it, which competes with the GPUs for the rented cores.
if [ "$CPU_MINING" != "true" ]; then
  CMD+=( --disable-cpu )
fi

# Append EXTRA tokens if provided (space-splitting)
if [ -n "$EXTRA" ]; then
  read -r -a EXTRA_ARR <<< "$EXTRA"
  CMD+=( "${EXTRA_ARR[@]}" )
fi

# exec so the miner is PID 1 and receives the container's stop signal
echo "Running: ${CMD[*]}"
exec "${CMD[@]}"
