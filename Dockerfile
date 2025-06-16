FROM node:20-slim

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3-full \
    python3-pip \
    build-essential \
    vim \
    wget \
    zip \
    unzip \
    gosu \
    gnupg \
    pinentry-curses \
    docker.io \
    docker-compose \
    && rm -rf /var/lib/apt/lists/*

# Install Claude Code globally
RUN npm install -g @anthropic-ai/claude-code

# Create a non-root user
RUN useradd -m -s /bin/bash claude

# Create workspace directory
RUN mkdir -p /workspace && chown claude:claude /workspace

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]