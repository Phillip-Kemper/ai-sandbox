#!/bin/bash
# Claude Code Docker Aliases and Functions
# Add this to your ~/.bashrc or ~/.zshrc:
# source /path/to/ai-sandbox/claude-aliases.sh

# Get the directory where this script is located
# Use a more reliable method to find the script directory
if [[ -n "${BASH_SOURCE[0]}" ]]; then
    CLAUDE_DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
elif [[ -n "${(%):-%x}" ]]; then
    # For zsh
    CLAUDE_DOCKER_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
else
    # Fallback - assume it's in ~/ai-sandbox
    CLAUDE_DOCKER_DIR="$HOME/ai-sandbox"
fi

# Basic aliases - using functions instead of aliases for proper expansion
claude-here() {
    "$CLAUDE_DOCKER_DIR/run-claude.sh" "$(pwd)"
    # Auto-setup GPG after container starts (wait longer for container to be ready)
    sleep 5 && "$CLAUDE_DOCKER_DIR/setup-gpg.sh" 2>/dev/null &
}

claude-with-config() {
    local project_name=$(basename "$(pwd)")
    local config_dir="$HOME/.claude-configs/$project_name"
    
    # Create config directory if it doesn't exist
    if [ ! -d "$config_dir" ]; then
        echo "📁 Creating Claude config directory: $config_dir"
        mkdir -p "$config_dir"
        echo "💡 Run 'claude-init' to create a CLAUDE.md file for this project"
    fi
    
    "$CLAUDE_DOCKER_DIR/run-claude.sh" "$(pwd)" "$config_dir"
    # Auto-setup GPG after container starts (wait longer for container to be ready)
    sleep 5 && "$CLAUDE_DOCKER_DIR/setup-gpg.sh" 2>/dev/null &
}

# Function to initialize Claude config for current project
claude-init() {
    local project_name=${1:-$(basename $(pwd))}
    local config_dir="$HOME/.claude-configs/$project_name"
    
    mkdir -p "$config_dir"
    
    if [ ! -f "$config_dir/CLAUDE.md" ]; then
        cat > "$config_dir/CLAUDE.md" << EOF
# $project_name

## Project Overview
[Describe what this project does and its main purpose]

## Key Conventions
- [Add your coding standards and style guides]
- [File organization patterns]
- [Testing approaches and frameworks used]
- [Build/deployment processes]

## Important Files & Directories
- [List key files Claude should know about]
- [Configuration files locations]
- [Documentation locations]

## Development Workflow
- [How to set up the development environment]
- [How to run tests]
- [How to build/deploy]

## Context & Notes
- [Any other important context for Claude]
- [Common gotchas or known issues]
- [Dependencies and external services]
EOF
        echo "✅ Created Claude config at: $config_dir/CLAUDE.md"
        echo "📝 Edit the config file, then run: claude-with-config"
        
        # Open in editor if available
        if command -v code &> /dev/null; then
            echo "🚀 Opening in VS Code..."
            code "$config_dir/CLAUDE.md"
        elif command -v vim &> /dev/null; then
            echo "📝 Opening in vim..."
            vim "$config_dir/CLAUDE.md"
        fi
    else
        echo "ℹ️  Config already exists at: $config_dir/CLAUDE.md"
        echo "📝 Edit it with: claude-config-edit $project_name"
    fi
}

# Function to run Claude with a specific project config
claude-run() {
    local project_path=${1:-$(pwd)}
    local project_name=${2:-$(basename "$project_path")}
    local config_dir="$HOME/.claude-configs/$project_name"
    
    if [ -f "$config_dir/CLAUDE.md" ]; then
        echo "🔧 Using config from: $config_dir"
        "$CLAUDE_DOCKER_DIR/run-claude.sh" "$project_path" "$config_dir"
    else
        echo "⚠️  No config found for $project_name"
        echo "💡 Create one with: claude-init $project_name"
        echo "🚀 Running without config..."
        "$CLAUDE_DOCKER_DIR/run-claude.sh" "$project_path"
    fi
}

# Function to quickly edit a config
claude-config-edit() {
    local project_name=${1:-$(basename $(pwd))}
    local config_file="$HOME/.claude-configs/$project_name/CLAUDE.md"
    
    if [ -f "$config_file" ]; then
        if command -v code &> /dev/null; then
            code "$config_file"
        elif command -v vim &> /dev/null; then
            vim "$config_file"
        else
            echo "📁 Config file location: $config_file"
        fi
    else
        echo "❌ No config found for: $project_name"
        echo "💡 Create one with: claude-init $project_name"
    fi
}

# Function to securely import GPG key into running container
claude-setup-gpg() {
    "$CLAUDE_DOCKER_DIR/setup-gpg.sh" "$@"
}

# Quietly load aliases without spam