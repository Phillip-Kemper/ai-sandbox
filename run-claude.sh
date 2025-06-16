#!/bin/bash

# Check if project path is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-path> [claude-config-path]"
    echo "Example: $0 /path/to/your/project"
    echo "Example: $0 /path/to/your/project ~/.claude-configs/my-project"
    exit 1
fi

PROJECT_PATH="$1"
CLAUDE_CONFIG_PATH="$2"

# Check if project path exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "Error: Directory $PROJECT_PATH does not exist"
    exit 1
fi

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Error: ANTHROPIC_API_KEY environment variable is not set"
    echo "Please set it with: export ANTHROPIC_API_KEY=your_api_key"
    exit 1
fi

# Build the Docker image from the script's directory
echo "Building Claude Code Docker image..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
docker build -t claude-code "$SCRIPT_DIR"

# Prepare docker run command
DOCKER_CMD="docker run -it --name claude-session --rm"
DOCKER_CMD="$DOCKER_CMD --network host"  # Access host services
DOCKER_CMD="$DOCKER_CMD -v \"$PROJECT_PATH:/workspace\""
DOCKER_CMD="$DOCKER_CMD -e ANTHROPIC_API_KEY=\"$ANTHROPIC_API_KEY\""

# Mount persistent Claude config directory
mkdir -p "$HOME/.claude-docker-config"
DOCKER_CMD="$DOCKER_CMD -v \"$HOME/.claude-docker-config:/home/claude\""

# Mount host git config for seamless git operations
if [ -f "$HOME/.gitconfig" ]; then
    DOCKER_CMD="$DOCKER_CMD -v \"$HOME/.gitconfig:/home/claude/.gitconfig:ro\""
fi

# Note: GPG keys are imported securely using setup-gpg.sh script
# No need to mount the entire GPG directory for security reasons

# Add CLAUDE.md config mount if provided
if [ -n "$CLAUDE_CONFIG_PATH" ]; then
    if [ ! -d "$CLAUDE_CONFIG_PATH" ]; then
        echo "Error: Claude config directory $CLAUDE_CONFIG_PATH does not exist"
        echo "Create it with: mkdir -p $CLAUDE_CONFIG_PATH"
        exit 1
    fi
    DOCKER_CMD="$DOCKER_CMD -v \"$CLAUDE_CONFIG_PATH:/claude-config\""
    echo "Claude config mounted from: $CLAUDE_CONFIG_PATH"
fi

DOCKER_CMD="$DOCKER_CMD claude-code"

# Run the container
echo "Starting Claude Code container..."
echo "Project mounted at: $PROJECT_PATH"

eval $DOCKER_CMD