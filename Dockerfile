# Use modern Ubuntu as base
FROM ubuntu:22.04

# Set environment variables to avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV NODE_OPTIONS="--no-warnings"
ENV PYTHONDONTWRITEBYTECODE=1

# Install system dependencies and add repositories
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    gnupg \
    ca-certificates \
    build-essential \
    software-properties-common \
    apt-transport-https \
    unzip \
    zip \
    tar \
    gzip \
    sudo \
    lsb-release \
    && rm -rf /var/lib/apt/lists/*

# Add all external repositories and install packages
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
    && echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/claude-archive-keyring.gpg] https://packages.anthropic.com/claude-cli/ stable main" | tee /etc/apt/sources.list.d/claude-cli.list \
    # Update and install all packages
    && apt-get update \
    && apt-get install -y \
        nodejs \
        dotnet-sdk-8.0 \
        python3 \
        python3-pip \
        python3-venv \
        neovim \
        gh \
        claude \
    && rm -rf /var/lib/apt/lists/* \
    # Upgrade pip
    && python3 -m pip install --upgrade pip

# Install Opencode CLI and Pi coding agent
RUN curl -fsSL https://github.com/opencodeai/opencode-cli/releases/latest/download/opencode-linux-amd64.tar.gz -L | tar -xz -C /tmp \
    && mv /tmp/opencode /usr/local/bin/ \
    && chmod +x /usr/local/bin/opencode \
    && curl -fsSL https://pi-coding-agent.com/install.sh | bash

# Create a non-root user for security
RUN useradd -m -s /bin/bash -G sudo,users developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

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