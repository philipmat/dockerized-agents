# ---- Builder stage: fetch and build tools that don't need to persist build deps ----
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install Opencode CLI
RUN curl -fsSL https://github.com/opencodeai/opencode-cli/releases/latest/download/opencode-linux-amd64.tar.gz -L | tar -xz -C /tmp \
    && mv /tmp/opencode /usr/local/bin/ \
    && chmod +x /usr/local/bin/opencode

# Install Pi coding agent
# NOTE: adjust COPY path below if the install script places the binary elsewhere
RUN curl -fsSL https://pi-coding-agent.com/install.sh | bash

# ---- Runtime stage: no build-essential, no sudo ----
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV NODE_OPTIONS="--no-warnings"
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies (no build-essential, no sudo)
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    gnupg \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    unzip \
    zip \
    tar \
    gzip \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add external repositories (rarely changes)
RUN set -ex \
    # Node.js repository
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /usr/share/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    # .NET repository
    && wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    # GitHub CLI repository
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    # Claude repository
    && wget -q https://packages.anthropic.com/claude-archive-keyring.gpg -O /tmp/claude-archive-keyring.gpg \
    && gpg --dearmor -o /etc/apt/keyrings/claude-archive-keyring.gpg /tmp/claude-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/claude-archive-keyring.gpg] https://packages.anthropic.com/claude-cli/ stable main" | tee /etc/apt/sources.list.d/claude-cli.list

# Install runtime languages (changes on major upgrades)
RUN apt-get update && apt-get install -y \
    nodejs \
    dotnet-sdk-8.0 \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip (own layer — changes infrequently)
RUN python3 -m pip install --upgrade pip

# Install dev tools (changes more often)
RUN apt-get update && apt-get install -y \
    neovim \
    gh \
    claude \
    && rm -rf /var/lib/apt/lists/*

# Copy tools from builder stage
COPY --from=builder /usr/local/bin/opencode /usr/local/bin/opencode
COPY --from=builder /usr/local/bin/pi /usr/local/bin/pi

# Create non-root user without sudo
RUN useradd -m -s /bin/bash -G users developer

# Set working directory
WORKDIR /workspace

# Switch to the non-root user
USER developer

# Configure shell
SHELL ["/bin/bash", "-c"]

# Default entry point is interactive shell
ENTRYPOINT ["/bin/bash"]

# Expose default ports for potential services
EXPOSE 3000 8000 8080 8888

# Health check (optional)
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD echo "Container is healthy" || exit 1
