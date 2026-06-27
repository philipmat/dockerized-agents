#!/bin/bash
# Forward host MCP server ports so that 127.0.0.1 URLs in agent configs
# resolve correctly inside the container (rider:64342, pycharm:64343).
socat TCP-LISTEN:64342,fork,reuseaddr TCP:host.docker.internal:64342 2>/dev/null &
socat TCP-LISTEN:64343,fork,reuseaddr TCP:host.docker.internal:64343 2>/dev/null &

# echo "preparing sql binding"
# sql server running on port 1433 in another container
# socat TCP-LISTEN:1433,bind=127.0.0.1,fork,reuseaddr TCP:host.docker.internal:1433
socat TCP-LISTEN:1433,fork,reuseaddr TCP:host.docker.internal:1433 2>/dev/null &

# Disable the sandbox inside the container (not needed in Docker).
node -e "
    const fs = require('fs');
    const p = process.env.HOME + '/.claude/settings.local.json';
    let s = {};
    try { s = JSON.parse(fs.readFileSync(p, 'utf8')); } catch (_) {}
    s.dangerouslyDisableSandbox = true;
    fs.writeFileSync(p, JSON.stringify(s, null, 2));
"

# echo "starting agent"
exec "$@"
