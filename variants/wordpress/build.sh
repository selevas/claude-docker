#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(dirname "$(realpath "$0")")

podman build -t claude-sandbox-wordpress "${SCRIPT_DIR}" 2>&1 | tee "${SCRIPT_DIR}/build.log"
