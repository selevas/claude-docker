FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_MAJOR=24

# Base system tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    gnupg \
    git \
    unzip \
    zip \
    jq \
    less \
    vim \
    nano \
    tmux \
    procps \
    lsof \
    file \
    tree \
    xz-utils \
    build-essential \
    libssl-dev \
    poppler-utils \
    # Python
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    # Perl
    perl \
    cpanminus \
    # Shell
    bash \
    zsh \
    && rm -rf /var/lib/apt/lists/*

# Node.js (via NodeSource), with npm bumped to latest afterward since the
# NodeSource package pins whatever npm shipped with that Node release.
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && npm install -g npm@latest

# nvm, for installing/switching to specific Node or npm versions on demand.
# The NodeSource install above remains the default `node`/`npm` on PATH;
# nvm only takes over once a shell sources it (via .bashrc/.zshrc below) and
# `nvm use` is run.
ARG NVM_VERSION=0.40.7
ENV NVM_DIR=/root/.nvm
RUN curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh" | bash \
    && for rc in /root/.bashrc /root/.zshrc; do \
        touch "$rc"; \
        grep -q 'NVM_DIR' "$rc" || printf '%s\n' \
            'export NVM_DIR="$HOME/.nvm"' \
            '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' \
            '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' \
            >> "$rc"; \
    done

# ripgrep and fd (fast search tools Claude Code uses heavily)
RUN curl -LO https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb \
    && dpkg -i ripgrep_14.1.1-1_amd64.deb \
    && rm ripgrep_14.1.1-1_amd64.deb

RUN curl -LO https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-musl_10.2.0_amd64.deb \
    && dpkg -i fd-musl_10.2.0_amd64.deb \
    && rm fd-musl_10.2.0_amd64.deb

# gh CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
        | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
        > /etc/apt/sources.list.d/github-cli.list \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Claude Code CLI
COPY managed-settings.json /etc/claude-code/managed-settings.json
ARG CLAUDE_CODE_VERSION=2.1.186
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} \
    && mkdir -p /root/.local/bin \
    && ln -s "$(which claude)" /root/.local/bin/claude

# In rootless Podman, UID 0 inside the container maps to the host user, so
# bind-mounted files owned by the host user are accessible as root here.
# HOME is set to match the .claude bind mount target in run.sh.
ENV HOME=/root
ENV PNPM_HOME=/root/.local/share/pnpm
ENV PATH="/root/.local/bin:${PNPM_HOME}:${PATH}"

# pnpm, pinned and baked into the image.
#
# Installed via npm rather than corepack so the binary is present at build
# time with no runtime network round trip and no version resolution.
#
# npm itself is NOT removed: it ships inside the NodeSource nodejs package
# and installs the Claude Code CLI above. pnpm is added alongside it, and is
# the package manager for the workspace.
ARG PNPM_VERSION=11.25.0
RUN npm install -g pnpm@${PNPM_VERSION}

# pnpm configuration, written to the home-level .npmrc.
#
# manage-package-manager-versions=false
#   pnpm 9+ otherwise honours the "packageManager" field in package.json and
#   self-downloads a matching version on every fresh container. Disabling it
#   means the image's pinned PNPM_VERSION above always wins.
#
# store-dir=/workspace/.pnpm-store
#   pnpm hardlinks from its content-addressable store into node_modules, and
#   hardlinks cannot cross filesystems. Keeping the store on the bind-mounted
#   workspace (same filesystem as node_modules) preserves hardlinking and lets
#   the store survive container restarts without an extra host bind mount.
#   Add .pnpm-store/ to .gitignore.
RUN mkdir -p /root \
    && printf '%s\n' \
        'manage-package-manager-versions=false' \
        'store-dir=/workspace/.pnpm-store' \
        >> /root/.npmrc

WORKDIR /workspace

CMD ["bash"]
