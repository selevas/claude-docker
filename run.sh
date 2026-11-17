#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-sandbox"
PROJECT_NAME=$(basename "$(pwd)")

# Dev server port mapping, published on the host's loopback only.
EXTERNAL_PORT="${DEV_EXTERNAL_PORT:-5173}"
INTERNAL_PORT="${DEV_INTERNAL_PORT:-5173}"

# -p overrides DEV_EXTERNAL_PORT, e.g. to run several sandboxes side by side.
while getopts ":p:" opt; do
  case "${opt}" in
    p) EXTERNAL_PORT="${OPTARG}" ;;
    :) echo "Option -${OPTARG} requires a port" >&2; exit 1 ;;
    *) echo "Unknown option: -${OPTARG}" >&2; exit 1 ;;
  esac
done
shift $((OPTIND - 1))

# Claude Code stores onboarding state here (outside ~/.claude/)
touch "${HOME}/.claude.json"

# pnpm store, shared by every sandbox and kept across container runs.
# Mounted at /workspace/.pnpm-store, which the image's .npmrc points at.
PNPM_STORE="${PNPM_STORE_DIR:-${HOME}/.cache/claude-sandbox/pnpm-store}"
mkdir -p "${PNPM_STORE}"

# Build extra mount flags from any additional arguments.
# Usage: claude-docker [-p external-port] [extra-path ...]
# Each path is mounted read-write at /workspace/<dirname>.
EXTRA_MOUNTS=()
for dir in "$@"; do
  abs=$(realpath "${dir}")
  name=$(basename "${abs}")
  EXTRA_MOUNTS+=(-v "${abs}":/workspace/"${name}")
done

# To isolate network access, uncomment: --network none
# Note: this will break the Anthropic API connection.
podman run -it --rm \
  -v "${HOME}/.claude":/root/.claude \
  -v "${HOME}/.claude.json":/root/.claude.json \
  -v "$(pwd)":/workspace/"${PROJECT_NAME}" \
  -v "${PNPM_STORE}":/workspace/.pnpm-store \
  -v "${HOME}/.gitconfig":/root/.gitconfig:ro \
  -p "127.0.0.1:${EXTERNAL_PORT}:${INTERNAL_PORT}" \
  "${EXTRA_MOUNTS[@]+"${EXTRA_MOUNTS[@]}"}" \
  --workdir /workspace/"${PROJECT_NAME}" \
  "${IMAGE}" \
  bash
