#!/usr/bin/env bash
set -euo pipefail

IMAGE="claude-sandbox-wordpress"
PROJECT_NAME=$(basename "$(pwd)")
HOST_PORT="${WP_PORT:-8080}"

# Claude Code stores onboarding state here (outside ~/.claude/)
touch "${HOME}/.claude.json"

# wp-content (themes, plugins, uploads) persists in the project directory
mkdir -p "$(pwd)/wp-content"

# Build extra mount flags from any additional arguments
EXTRA_MOUNTS=()
for dir in "$@"; do
    abs=$(realpath "${dir}")
    name=$(basename "${abs}")
    EXTRA_MOUNTS+=(-v "${abs}":/workspace/"${name}")
done

# wordpress-db named volume persists the database across container runs
podman run -it --rm \
  -v "${HOME}/.claude":/root/.claude \
  -v "${HOME}/.claude.json":/root/.claude.json \
  -v "$(pwd)":/workspace/"${PROJECT_NAME}" \
  -v "$(pwd)/wp-content":/var/www/html/wp-content \
  -v wordpress-db:/var/lib/mysql \
  -v "${HOME}/.gitconfig":/root/.gitconfig:ro \
  -v "${HOME}/.ssh":/root/.ssh:ro \
  -p "0.0.0.0:${HOST_PORT}:8080" \
  -e WP_PORT="${HOST_PORT}" \
  "${EXTRA_MOUNTS[@]+"${EXTRA_MOUNTS[@]}"}" \
  --workdir /workspace/"${PROJECT_NAME}" \
  "${IMAGE}" \
  bash
