#!/bin/bash
# Forward host MCP server ports so that 127.0.0.1 URLs in agent configs
# resolve correctly inside the container (rider:64342, pycharm:64343).
socat TCP-LISTEN:64342,fork,reuseaddr TCP:host.docker.internal:64342 2>/dev/null &
socat TCP-LISTEN:64343,fork,reuseaddr TCP:host.docker.internal:64343 2>/dev/null &
exec "$@"
