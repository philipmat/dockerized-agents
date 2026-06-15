# AI Agents Development Container

This Dockerfile creates a modern development container with multiple AI agents and development tools pre-installed.

## Features

- **Base OS**: Ubuntu 22.04 (LTS)
- **AI Agents**:
  - GitHub Copilot CLI
  - Claude CLI
  - OpenCode CLI
  - Pi Coding Agent
- **Development Tools**:
  - .NET 8.0 SDK
  - Node.js LTS
  - Python 3 with pip
  - Neovim

## Prerequisites

- Docker installed on your host system
- Docker Compose (optional, for more complex scenarios)

## Building the Image

```bash
# Build the Docker image
docker build -t ai-agents-dev .

# Optional: Build with specific tag
docker build -t ai-agents-dev:latest .
```

## Running the Container

### Basic Usage

```bash
# Run container interactively with volume mount
docker run -it \
  --name ai-agents \
  -v "$(pwd):/workspace" \
  ai-agents-dev
```

### With Environment Variables

```bash
# Run with environment variables for AI tools
docker run -it \
  --name ai-agents \
  -v "$(pwd):/workspace" \
  -e GITHUB_TOKEN="your_github_token" \
  -e ANTHROPIC_API_KEY="your_claude_api_key" \
  -e OPENCODE_API_KEY="your_opencode_api_key" \
  ai-agents-dev
```

### With Port Mapping (if needed)

```bash
# Run with port mapping for development servers
docker run -it \
  --name ai-agents \
  -v "$(pwd):/workspace" \
  -p 3000:3000 \
  -p 8000:8000 \
  -e NODE_ENV="development" \
  ai-agents-dev
```

### Using Docker Compose

Create a `docker-compose.yml` file:

```yaml
version: '3.8'
services:
  ai-agents:
    build: .
    container_name: ai-agents
    volumes:
      - .:/workspace
    environment:
      - GITHUB_TOKEN=your_github_token
      - ANTHROPIC_API_KEY=your_claude_api_key
      - OPENCODE_API_KEY=your_opencode_api_key
      - NODE_ENV=development
    working_dir: /workspace
    stdin_open: true
    tty: true
```

Then run:

```bash
docker-compose up -d
docker-compose exec ai-agents bash
```

## Accessing the Container Shell

```bash
# Start a new session in the running container
docker exec -it ai-agents bash

# Or attach to an existing session
docker attach ai-agents
```

## AI Tool Setup and Usage

### GitHub Copilot

```bash
# Authenticate GitHub Copilot
gh auth login

# Enable GitHub Copilot in Neovim
nvim
# Inside Neovim, run: :Copilot enable
```

### Claude CLI

```bash
# Set up Claude CLI authentication
claude auth login

# Use Claude CLI
claude "your prompt here"
```

### OpenCode CLI

```bash
# Set up OpenCode CLI authentication
opencode auth

# Use OpenCode CLI
opencode "your prompt here"
```

### Pi Coding Agent

```bash
# Pi should be ready to use
pi "your coding task here"
```

## Environment Variables

### Common Variables

```bash
# Development environment
NODE_ENV=production
PYTHONPATH=/workspace
DOTNET_ENVIRONMENT=Production

# AI Tool Configuration
GITHUB_TOKEN=ghp_your_token_here
ANTHROPIC_API_KEY=sk-ant-api03_your_key
OPENCODE_API_KEY=your_opencode_key

# Editor Configuration
EDITOR=nvim
VISUAL=nvim
```

### Example Usage with Environment Variables

```bash
# Run container with development environment
docker run -it \
  --name ai-agents-dev \
  -v "$(pwd):/workspace" \
  -e NODE_ENV="development" \
  -e PYTHONPATH="/workspace" \
  -e EDITOR="nvim" \
  -e GITHUB_TOKEN="your_token" \
  ai-agents-dev

# Inside the container:
# cd /workspace
# npm init           # Node.js project
# dotnet new web    # .NET project
# python3 -m venv venv && source venv/bin/activate  # Python environment
```

## Volume Mounting

The container mounts your current working directory to `/workspace`, making it accessible to all tools and agents:

```bash
# Host directory -> Container directory
-v "/path/to/host/code:/workspace"

# For macOS users
-v "$HOME/Projects:/workspace"

# For Linux users
-v "$(pwd):/workspace"
```

## Development Workflow

1. **Start the container** with appropriate volume mounts and environment variables
2. **Access the shell**: `docker exec -it ai-agents bash`
3. **Set up your project**:
   ```bash
   cd /workspace
   # Initialize your project
   ```
4. **Use AI tools** for development assistance
5. **Code and develop** using the installed tools
6. **Changes are reflected** on your host system in real-time

## Troubleshooting

### Common Issues

1. **Permission issues**: Files created in the container may have different ownership
   ```bash
   # Fix ownership on host
   sudo chown -R $USER:$USER /path/to/host/code
   ```

2. **AI tool authentication**: Ensure API tokens are correctly set as environment variables

3. **Port conflicts**: Change port mappings if host ports are already in use

### Container Management

```bash
# List running containers
docker ps

# Stop container
docker stop ai-agents

# Remove container
docker rm ai-agents

# View container logs
docker logs ai-agents

# Start stopped container
docker start ai-agents
```

## Security Notes

- API tokens are passed as environment variables - consider using Docker secrets for production
- The container runs as a non-root user for security
- Volume mounts allow direct access to host files - be careful with sensitive data

## Customization

You can extend this Dockerfile by:
- Adding more development tools
- Installing specific AI model clients
- Setting up additional environment configurations
- Adding startup scripts for specific workflows