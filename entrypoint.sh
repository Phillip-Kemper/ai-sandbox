#!/bin/bash

# Fix ownership of the workspace to match the claude user (skip .git to avoid permission errors)
find /workspace -not -path '/workspace/.git*' -exec chown claude:claude {} + 2>/dev/null || true

# Copy CLAUDE.md from config mount if it exists
if [ -f "/claude-config/CLAUDE.md" ]; then
    echo "Copying CLAUDE.md from config directory..."
    cp /claude-config/CLAUDE.md /workspace/CLAUDE.md
    chown claude:claude /workspace/CLAUDE.md
    echo "CLAUDE.md copied to workspace"
fi

# Switch to claude user and execute the command
# If no command specified, default to claude --dangerously-skip-permissions
if [ $# -eq 0 ]; then
    echo "Starting Claude Code with --dangerously-skip-permissions..."
    exec gosu claude claude --dangerously-skip-permissions
else
    exec gosu claude "$@"
fi