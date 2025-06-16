# Claude Code Docker Setup

A containerized environment for running Claude Code with automatic project mounting and permission handling.

## Quick Start

1. Set your API key:
   ```bash
   export ANTHROPIC_API_KEY=your_api_key_here
   ```

2. Run Claude Code on any project:
   ```bash
   ./run-claude.sh /path/to/your/project
   ```

3. Inside the container, run Claude with:
   ```bash
   claude --skip-check
   ```

## CLAUDE.md Configuration

Keep project-specific Claude configurations separate from your git repo:

1. Create a config directory for your project:
   ```bash
   mkdir -p ~/.claude-configs/my-project
   ```

2. Create your CLAUDE.md file:
   ```bash
   cat > ~/.claude-configs/my-project/CLAUDE.md << 'EOF'
   # My Project Context
   
   This project is a web application built with React and Node.js.
   
   ## Key conventions:
   - Use TypeScript for all new code
   - Follow the existing component structure in src/components/
   - API routes are in src/api/
   EOF
   ```

3. Run with config mounting:
   ```bash
   ./run-claude.sh /path/to/your/project ~/.claude-configs/my-project
   ```

The CLAUDE.md file will be automatically copied to your project workspace inside the container, giving Claude context without polluting your git repository.

## GPG Commit Signing (Secure)

For secure git commit signing, use the ephemeral key import approach:

1. Start your container:
   ```bash
   claude-with-config
   ```

2. Import your signing key securely (from another terminal):
   ```bash
   claude-setup-gpg
   # Or specify a specific key: claude-setup-gpg YOUR_KEY_ID
   ```

3. Now you can sign commits inside the container:
   ```bash
   git commit -m "Your commit message"  # Automatically signed
   ```

**Security Benefits:**
- Only your signing key is imported, not your entire keyring
- Key exists only in container memory, never on disk
- Key is automatically removed when container stops
- No persistent exposure of your GPG keys

## Architecture Explanation

### Why This Setup?

**Security-First Design:**
- Runs as non-root user (`claude`) inside container
- Uses `gosu` for safe user switching (better than `sudo` in containers)
- Isolates Claude Code environment from host system

**Permission Handling:**
- **Problem**: When mounting host directories into containers, file ownership can cause permission errors
- **Solution**: Entrypoint script fixes ownership at runtime using `chown` 
- **Why Runtime**: Volume mounts happen when container starts, not when image builds
- **gosu**: Safely switches from root (needed for `chown`) to `claude` user for running processes

**Tool Selection:**
- **Node.js 20**: Required for Claude Code installation
- **Essential Tools**: git, python3, build tools for most development workflows  
- **gosu**: Standard container pattern for user switching without security risks

## Shell Aliases (Recommended)

For even easier usage, add shell aliases to your profile:

```bash
# Add to ~/.zshrc or ~/.bashrc
source ~/ai-sandbox/claude-aliases.sh
```

Then use these convenient commands:
- `claude-here` - Run Claude on current directory
- `claude-with-config` - Run Claude with config for current directory name
- `claude-init [name]` - Initialize CLAUDE.md config for project
- `claude-run [path] [name]` - Run Claude with specific project and config
- `claude-setup-gpg [key-id]` - Securely import GPG signing key into container

## Files

- `Dockerfile`: Container definition with Claude Code and tools
- `entrypoint.sh`: Handles file ownership and user switching
- `run-claude.sh`: Wrapper script for easy usage
- `claude-aliases.sh`: Shell aliases and helper functions
- `setup-gpg.sh`: Secure GPG key import utility
- `README.md`: This documentation

## Manual Usage

Build and run manually if needed:

```bash
# Build image
docker build -t claude-code .

# Run container (basic)
docker run -it --rm \
  -v "/path/to/project:/workspace" \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  claude-code

# Run container with CLAUDE.md config
docker run -it --rm \
  -v "/path/to/project:/workspace" \
  -v "~/.claude-configs/my-project:/claude-config" \
  -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
  claude-code
```
