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
    && echo "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_24.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    # .NET repository
    && wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb \
    # GitHub CLI repository
    && curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    echo "Repositories configured"

# Install runtime languages (changes on major upgrades)
RUN apt-get update && apt-get install -y \
    nodejs \
    dotnet-sdk-8.0 \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Install .NET 10 SDK via the official script (not yet in Ubuntu 22.04 APT feed)
RUN curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh \
    && chmod +x /tmp/dotnet-install.sh \
    && /tmp/dotnet-install.sh --channel 10.0 --install-dir /usr/local/dotnet10 \
    && rm /tmp/dotnet-install.sh
ENV PATH="/usr/local/dotnet10:$PATH"

# Upgrade pip (own layer — changes infrequently)
RUN python3 -m pip install --upgrade pip

# Install dev tools + Playwright system dependencies
RUN apt-get update && apt-get install -y \
    neovim \
    gh \
    fd-find ripgrep \
    bubblewrap \
    socat \
    libglib2.0-0 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libexpat1 \
    libxcb1 \
    libxkbcommon0 \
    libx11-6 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libpango-1.0-0 \
    libcairo2 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Install npm-based tools (Node.js is available at this point)
RUN npm install -g npm@latest
RUN npm install --loglevel verbose -g \
    @anthropic-ai/claude-code \
    @earendil-works/pi-coding-agent \
    opencode-ai \
    playwright

# Install Playwright browsers to a shared location accessible by all users
ENV PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
RUN playwright install chromium && chmod -R 755 /ms-playwright

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
