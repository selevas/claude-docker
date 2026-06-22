FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_MAJOR=22

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

# Node.js (via NodeSource)
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/*

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
RUN npm install -g @anthropic-ai/claude-code \
    && mkdir -p /root/.local/bin \
    && ln -s "$(which claude)" /root/.local/bin/claude

# In rootless Podman, UID 0 inside the container maps to the host user, so
# bind-mounted files owned by the host user are accessible as root here.
# HOME is set to match the .claude bind mount target in run.sh.
ENV HOME=/root
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /workspace

CMD ["bash"]
