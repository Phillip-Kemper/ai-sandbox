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

# Initialize GPG directory for the claude user
mkdir -p /home/claude/.gnupg
chown claude:claude /home/claude/.gnupg
chmod 700 /home/claude/.gnupg

# Auto-import GPG key if CLAUDE_GPG_KEY_ID is set
if [ -n "$CLAUDE_GPG_KEY_ID" ]; then
    echo "Auto-importing GPG key: $CLAUDE_GPG_KEY_ID"
    if [ -p /tmp/gpg_import_pipe ]; then
        gosu claude gpg --import --quiet < /tmp/gpg_import_pipe 2>/dev/null || true
        rm -f /tmp/gpg_import_pipe
    fi
fi

# Switch to claude user and execute the command
# If no command specified, default to claude --dangerously-skip-permissions
if [ $# -eq 0 ]; then
    echo "Starting Claude Code with --dangerously-skip-permissions..."
    exec gosu claude bash -c "
        export GPG_TTY=\$(tty)
        export PINENTRY_USER_DATA=USE_CURSES=1
        claude --dangerously-skip-permissions
    "
else
    exec gosu claude bash -c "
        export GPG_TTY=\$(tty)
        export PINENTRY_USER_DATA=USE_CURSES=1
        $*
    "
fi