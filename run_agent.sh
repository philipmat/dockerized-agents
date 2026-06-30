#!/bin/bash
set -e

AGENT="$1"
shift

if [[ -z "$AGENT" ]]; then
    echo "Usage: $0 <agent>"
    echo "Agents: claude, codex, pi, opencode"
    exit 1
fi

CONTAINER_HOME="/home/developer"
ENV_ARGS=()
# Each entry is "host_path:container_path" (file or directory)
CONFIG_MOUNTS=()

case "$AGENT" in
    claude)
        # mount special files in case the host also runs normal Claude
        # the reason for the separation is that host might run with a different config,
        # for example sandboxed Claude
        CONFIG_MOUNTS=(
            "$HOME/.claude-dockerized:$CONTAINER_HOME/.claude"
            "$HOME/.claude-dockerized.json:$CONTAINER_HOME/.claude.json"
        )
        AGENT_CMD="claude --dangerously-skip-permissions"
        # OAuth tokens live in macOS Keychain, not in claude.json.
        # Pass ANTHROPIC_API_KEY if set; otherwise the user must run /login inside.
        if [[ -n "$ANTHROPIC_API_KEY" ]]; then
            ENV_ARGS=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
        else
            echo "Note: ANTHROPIC_API_KEY is not set. Run /login inside the container if needed."
        fi
        ;;
    codex)
        CONFIG_MOUNTS=(
            "$HOME/.codex:$CONTAINER_HOME/.codex"
        )
        AGENT_CMD="codex --dangerously-bypass-approvals-and-sandbox"
        [[ -n "$OPENAI_API_KEY" ]] && ENV_ARGS=(-e "OPENAI_API_KEY=$OPENAI_API_KEY")
        ;;
    pi)
        CONFIG_MOUNTS=(
            "$HOME/.pi:$CONTAINER_HOME/.pi"
        )
        AGENT_CMD="pi --approve "
        ;;
    opencode)
        CONFIG_MOUNTS=(
            "$HOME/.config/opencode:$CONTAINER_HOME/.config/opencode"
        )
        AGENT_CMD="opencode"
        ;;
    *)
        echo "Unknown agent: $AGENT. Choose from: claude, codex, pi, opencode"
        exit 1
        ;;
esac

for arg in "$@"; do
    AGENT_CMD+=" $(printf '%q' "$arg")"
done

# Ensure host config paths exist so mounts don't create them as root-owned
for mount in "${CONFIG_MOUNTS[@]}"; do
    host_path="${mount%%:*}"
    if [[ "$host_path" == */ ]] || [[ ! "$host_path" == *.* ]]; then
        mkdir -p "$host_path"
    else
        # Looks like a file — ensure its parent dir exists and touch the file
        mkdir -p "$(dirname "$host_path")"
        [[ -e "$host_path" ]] || touch "$host_path"
    fi
done

# Build -v flags from CONFIG_MOUNTS
VOLUME_ARGS=()
for mount in "${CONFIG_MOUNTS[@]}"; do
    VOLUME_ARGS+=(-v "$mount")
done

# Find next available name (only check running containers; --rm cleans up stopped ones)
INDEX=1
while docker ps --format '{{.Names}}' | grep -q "^${AGENT}-${INDEX}$"; do
    ((INDEX++))
done
CONTAINER_NAME="${AGENT}-${INDEX}"

echo "Starting $CONTAINER_NAME"
echo "  workspace : $(pwd) -> /workspace"
for mount in "${CONFIG_MOUNTS[@]}"; do
    echo "  config    : $mount"
done

# could add
#    --network container:<mssql container name>
# to bind localhost to the sql server's network
# but this causes other issues
exec docker run --rm -it \
    --name "$CONTAINER_NAME" \
    --security-opt seccomp=unconfined \
    --add-host=host.docker.internal:host-gateway \
    "${ENV_ARGS[@]}" \
    -v "$(pwd):/workspace" \
    "${VOLUME_ARGS[@]}" \
    ai-agents-dev \
    /bin/bash -c "$AGENT_CMD"
