#!/bin/bash
set -e

AGENT="$1"

if [[ -z "$AGENT" ]]; then
    echo "Usage: $0 <agent>"
    echo "Agents: claude, codex, pi, opencode"
    exit 1
fi

CONTAINER_HOME="/home/developer"
ENV_ARGS=()

case "$AGENT" in
    claude)
        HOST_CONFIG="$HOME/.claude"
        CONTAINER_CONFIG="$CONTAINER_HOME/.claude"
        # OAuth tokens live in macOS Keychain, not in claude.json.
        # Pass ANTHROPIC_API_KEY if set; otherwise the user must run /login inside.
        if [[ -n "$ANTHROPIC_API_KEY" ]]; then
            ENV_ARGS=(-e "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY")
        else
            echo "Note: ANTHROPIC_API_KEY is not set. Run /login inside the container if needed."
        fi
        ;;
    codex)
        HOST_CONFIG="$HOME/.codex"
        CONTAINER_CONFIG="$CONTAINER_HOME/.codex"
        [[ -n "$OPENAI_API_KEY" ]] && ENV_ARGS=(-e "OPENAI_API_KEY=$OPENAI_API_KEY")
        ;;
    pi)
        HOST_CONFIG="$HOME/.pi"
        CONTAINER_CONFIG="$CONTAINER_HOME/.pi"
        ;;
    opencode)
        HOST_CONFIG="$HOME/.config/opencode"
        CONTAINER_CONFIG="$CONTAINER_HOME/.config/opencode"
        ;;
    *)
        echo "Unknown agent: $AGENT. Choose from: claude, codex, pi, opencode"
        exit 1
        ;;
esac

# Ensure host config dir exists so the mount doesn't create it as root-owned
mkdir -p "$HOST_CONFIG"

# Find next available name (only check running containers; --rm cleans up stopped ones)
INDEX=1
while docker ps --format '{{.Names}}' | grep -q "^${AGENT}-${INDEX}$"; do
    ((INDEX++))
done
CONTAINER_NAME="${AGENT}-${INDEX}"

echo "Starting $CONTAINER_NAME"
echo "  workspace : $(pwd) -> /workspace"
echo "  config    : $HOST_CONFIG -> $CONTAINER_CONFIG"

exec docker run --rm -it \
    --name "$CONTAINER_NAME" \
    --security-opt seccomp=unconfined \
    "${ENV_ARGS[@]}" \
    -v "$(pwd):/workspace" \
    -v "$HOST_CONFIG:$CONTAINER_CONFIG" \
    ai-agents-dev
