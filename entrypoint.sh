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

echo "Running: ${CMD[*]}"

# SRBMiner is meant to run in a terminal (other SRBMiner images set tty: true or
# start it inside screen). Kubernetes and `docker run -d` give it none, so in that
# case give it a pseudo-terminal with script(1).
# If the miner dies, script exits with its exit code. On a stop signal, script
# sends the miner SIGTERM and then SIGKILL two seconds later.
if [ -t 1 ]; then
  exec "${CMD[@]}"
else
  export TERM="${TERM:-xterm}"
  SHELL=/bin/bash exec script -qefc "$(printf '%q ' "${CMD[@]}")" /dev/null
fi
