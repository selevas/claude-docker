#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-sandbox"
PROJECT_NAME=$(basename "$(pwd)")

# Claude Code stores onboarding state here (outside ~/.claude/)
touch "${HOME}/.claude.json"

# To isolate network access, uncomment: --network none
# Note: this will break the Anthropic API connection.
podman run -it --rm \
  -v "${HOME}/.claude":/root/.claude \
  -v "${HOME}/.claude.json":/root/.claude.json \
  -v "$(pwd)":/workspace/"${PROJECT_NAME}" \
  -v "${HOME}/.gitconfig":/root/.gitconfig:ro \
  -v "${HOME}/.ssh":/root/.ssh:ro \
  --workdir /workspace/"${PROJECT_NAME}" \
  "${IMAGE}" \
  bash
