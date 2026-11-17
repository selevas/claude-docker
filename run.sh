#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-sandbox"
PROJECT_NAME=$(basename "$(pwd)")

# Dev server port mapping, published on the host's loopback only.
EXTERNAL_PORT="${DEV_EXTERNAL_PORT:-5173}"
INTERNAL_PORT="${DEV_INTERNAL_PORT:-5173}"

# -p overrides DEV_EXTERNAL_PORT, e.g. to run several sandboxes side by side.
# --gcloud mounts the host's gcloud config and credentials (see below).
# getopts has no long options, so "-:" routes --name through as opt "-".
GCLOUD=0
while getopts ":p:-:" opt; do
  case "${opt}" in
    p) EXTERNAL_PORT="${OPTARG}" ;;
    -)
      case "${OPTARG}" in
        gcloud) GCLOUD=1 ;;
        *) echo "Unknown option: --${OPTARG}" >&2; exit 1 ;;
      esac
      ;;
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
# Usage: claude-docker [-p external-port] [--gcloud] [extra-path ...]
# Each path is mounted read-write at /workspace/<dirname>.
EXTRA_MOUNTS=()

# The host's gcloud config and credentials, so the sandbox runs as whatever
# account the host is signed into. Opt-in only, since it exposes every
# account and project configured on the host. Read-write, since gcloud
# refreshes tokens and writes its credential database here.
if [[ "${GCLOUD}" -eq 1 ]]; then
  GCLOUD_CONFIG="${CLOUDSDK_CONFIG:-${HOME}/.config/gcloud}"
  mkdir -p "${GCLOUD_CONFIG}"
  EXTRA_MOUNTS+=(-v "${GCLOUD_CONFIG}":/root/.config/gcloud)
fi

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
