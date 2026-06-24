#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-sandbox"
PROJECT_NAME=$(basename "$(pwd)")

# Claude Code stores onboarding state here (outside ~/.claude/)
touch "${HOME}/.claude.json"

# Build extra mount flags from any additional arguments.
# Usage: claude-docker [extra-path ...]
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
  -v "${HOME}/.gitconfig":/root/.gitconfig:ro \
  -v "${HOME}/.ssh":/root/.ssh:ro \
  "${EXTRA_MOUNTS[@]+"${EXTRA_MOUNTS[@]}"}" \
  --workdir /workspace/"${PROJECT_NAME}" \
  "${IMAGE}" \
  bash
