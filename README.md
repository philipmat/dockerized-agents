# AI Agents Development Container

A Docker container with multiple AI coding agents and development tools pre-installed.

## Features

- **Base OS**: Ubuntu 22.04 (LTS)
- **AI Agents**: Claude CLI, OpenCode CLI, Codex CLI, Pi Coding Agent
- **Development Tools**: .NET 8 & 10 SDK, Node.js 24 LTS, Python 3 with pip, Neovim

## Prerequisites

- Docker installed on your host system

## Building the Image

```bash
docker build -t ai-agents-dev .
```

## Running Agents

### Use `run_agent.sh`

Use `run_agent.sh` to launch any agent. It mounts your current directory as `/workspace`,
maps the agent's config from your host, and names containers automatically (e.g. `claude-1`, `claude-2`).

```bash
./run_agent.sh <agent> [args...]
```

**Agents:** `claude`, `codex`, `pi`, `opencode`

Any arguments after the agent name are passed directly to the agent command inside the container.

### Examples

```bash
# Start an interactive Claude session
./run_agent.sh claude

# Pass a prompt directly to Claude
./run_agent.sh claude -p "refactor this module for readability"

# Start Codex
./run_agent.sh codex

# Start OpenCode
./run_agent.sh opencode

# Start Pi
./run_agent.sh pi
```

### API Keys

Set the relevant environment variable before running and it will be forwarded automatically:

| Agent   | Environment variable |
|---------|----------------------|
| claude  | `ANTHROPIC_API_KEY`  |
| codex   | `OPENAI_API_KEY`     |

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
./run_agent.sh claude
```

If `ANTHROPIC_API_KEY` is not set for `claude`, you can authenticate inside the container with `/login`.

### Config persistence

Each agent's config directory is mounted from your host, so authentication and settings persist across container runs:

| Agent     | Host path               |
|-----------|-------------------------|
| claude    | `~/.claude`             |
| codex     | `~/.codex`              |
| pi        | `~/.pi`                 |
| opencode  | `~/.config/opencode`    |

## Running Multiple Agents

Each `run_agent.sh` invocation starts a new container in a separate terminal. Containers are named with an incrementing index (`claude-1`, `claude-2`, etc.) so they don't conflict.

```bash
# Terminal 1
./run_agent.sh claude

# Terminal 2 — runs alongside the first
./run_agent.sh claude
```

## Workspace

Your current working directory is mounted to `/workspace` inside the container. Changes made by the agent are reflected on your host in real time.

```bash
# Run from your project root
cd ~/Projects/my-app
./path/to/run_agent.sh claude
```


### Running the Container

You can also run the containers directly and start agents within it.

```bash
# Run container interactively with volume mount
docker run --rm -it  \
  --name ai-agents \
  -v "$(pwd):/workspace" \
  ai-agents-dev
```

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

## Troubleshooting

**Permission issues** — files created inside the container may be owned by a different UID:
```bash
sudo chown -R $USER:$USER .
```

**Authentication** — if an agent can't authenticate, check that the right API key env var is set, or log in interactively inside the container.

**Port conflicts** — if your agent starts a dev server, map ports with `-p` by running `docker run` directly with the same flags used in `run_agent.sh`.

### Container management

```bash
docker ps                  # list running agent containers
docker stop claude-1       # stop a specific container
docker logs claude-1       # view logs
```

## Security Notes

- API keys are passed as environment variables — avoid committing them to source control
- The container runs as a non-root user
- `--security-opt seccomp=unconfined` is required by some agents for full functionality
