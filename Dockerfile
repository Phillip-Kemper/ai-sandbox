FROM node:20-slim

# Build args early for better caching
ARG INSTALL_FOUNDRY=false
ARG INSTALL_NATS=false

# Install base system dependencies (rarely changes - good for cache)
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

# Install Claude Code (separate layer for npm cache)
RUN npm install -g @anthropic-ai/claude-code

# Create user early (needed for optional deps)
RUN useradd -m -s /bin/bash claude

# Install optional dependencies in single layer
RUN if [ "$INSTALL_FOUNDRY" = "true" ] || [ "$INSTALL_NATS" = "true" ]; then \
    # Install Foundry if requested \
    if [ "$INSTALL_FOUNDRY" = "true" ]; then \
        curl -L https://foundry.paradigm.xyz | bash && \
        ~/.foundry/bin/foundryup && \
        cp ~/.foundry/bin/* /usr/local/bin/ && \
        chmod +x /usr/local/bin/forge /usr/local/bin/cast /usr/local/bin/anvil /usr/local/bin/chisel; \
    fi; \
    # Install NATS CLI if requested \
    if [ "$INSTALL_NATS" = "true" ]; then \
        wget https://github.com/nats-io/natscli/releases/latest/download/nats-0.2.3-linux-amd64.zip && \
        unzip nats-0.2.3-linux-amd64.zip && \
        mv nats-0.2.3-linux-amd64/nats /usr/local/bin/ && \
        chmod +x /usr/local/bin/nats && \
        rm -rf nats-0.2.3-linux-amd64.zip nats-0.2.3-linux-amd64/; \
    fi; \
    fi

# Setup workspace and entrypoint (changes less frequently)
RUN mkdir -p /workspace && chown claude:claude /workspace
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace
ENTRYPOINT ["/entrypoint.sh"]