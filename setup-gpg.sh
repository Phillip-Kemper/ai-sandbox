#!/bin/bash
# Secure GPG Key Import for Claude Code Docker Container
# This script imports only the signing key needed, not the entire keyring

set -e

# Configuration
DEFAULT_KEY_ID="0D670F3E6403A2E9"  # Your signing key ID
CONTAINER_NAME="claude-session"

# Colors for output (only show if not running in background)
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    NC=''
fi

show_usage() {
    echo "Usage: $0 [KEY_ID]"
    echo ""
    echo "Securely imports a GPG signing key into the Claude Code container."
    echo ""
    echo "Arguments:"
    echo "  KEY_ID    GPG key ID to import (default: $DEFAULT_KEY_ID)"
    echo ""
    echo "Examples:"
    echo "  $0                           # Import default key"
    echo "  $0 0D670F3E6403A2E9          # Import specific key"
    echo ""
    echo "Note: Container must be running (start with claude-here or claude-with-config)"
}

# Parse arguments
KEY_ID="${1:-$DEFAULT_KEY_ID}"

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_usage
    exit 0
fi

# Silent mode for background execution
SILENT=false
if [[ ! -t 1 ]]; then
    SILENT=true
fi

if [[ "$SILENT" != "true" ]]; then
    echo -e "${YELLOW}🔐 Setting up GPG signing for Claude Code container...${NC}"
fi

# Check if key exists on host
if ! gpg --list-secret-keys "$KEY_ID" >/dev/null 2>&1; then
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${RED}❌ Error: GPG key $KEY_ID not found on host system${NC}"
        echo "Available keys:"
        gpg --list-secret-keys --keyid-format LONG | grep "sec" || echo "No secret keys found"
    fi
    exit 1
fi

# Find the running container
CONTAINER_ID=$(docker ps -q -f name="$CONTAINER_NAME" | head -1)

if [[ -z "$CONTAINER_ID" ]]; then
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${RED}❌ Error: No running Claude Code container found${NC}"
        echo "Start the container first with: claude-here or claude-with-config"
    fi
    exit 1
fi

if [[ "$SILENT" != "true" ]]; then
    echo -e "${GREEN}✅ Found running container: $CONTAINER_ID${NC}"
fi

# Get key information
KEY_INFO=$(gpg --list-secret-keys --keyid-format LONG "$KEY_ID" | grep "uid" | head -1 | sed 's/uid.*] //' 2>/dev/null || echo "Unknown")

if [[ "$SILENT" != "true" ]]; then
    echo -e "${YELLOW}📋 Importing key: $KEY_ID ($KEY_INFO)${NC}"
    echo -e "${YELLOW}🔄 Importing secret key...${NC}"
fi

# Import the secret key (run as claude user)
if gpg --export-secret-keys "$KEY_ID" | docker exec -i "$CONTAINER_ID" gosu claude gpg --import --quiet 2>/dev/null; then
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${GREEN}✅ Secret key imported successfully${NC}"
    fi
else
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${RED}❌ Failed to import secret key${NC}"
    fi
    exit 1
fi

# Import the public key (run as claude user)
if [[ "$SILENT" != "true" ]]; then
    echo -e "${YELLOW}🔄 Importing public key...${NC}"
fi

if gpg --export "$KEY_ID" | docker exec -i "$CONTAINER_ID" gosu claude gpg --import --quiet 2>/dev/null; then
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${GREEN}✅ Public key imported successfully${NC}"
    fi
else
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${RED}❌ Failed to import public key${NC}"
    fi
    exit 1
fi

# Set ultimate trust for the key (get the full fingerprint first)
if [[ "$SILENT" != "true" ]]; then
    echo -e "${YELLOW}🔄 Setting key trust level...${NC}"
fi

FINGERPRINT=$(gpg --list-secret-keys --with-colons "$KEY_ID" | grep "fpr" | head -1 | cut -d: -f10 2>/dev/null)
if [[ -n "$FINGERPRINT" ]]; then
    if echo "$FINGERPRINT:6:" | docker exec -i "$CONTAINER_ID" gosu claude gpg --import-ownertrust --quiet 2>/dev/null; then
        if [[ "$SILENT" != "true" ]]; then
            echo -e "${GREEN}✅ Key trust level set${NC}"
        fi
    else
        if [[ "$SILENT" != "true" ]]; then
            echo -e "${YELLOW}⚠️  Trust level setting failed, but key import successful${NC}"
        fi
    fi
fi

# Verify the import worked (run as claude user)
if docker exec "$CONTAINER_ID" gosu claude gpg --list-secret-keys --keyid-format LONG 2>/dev/null | grep -q "$KEY_ID"; then
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${GREEN}✅ GPG key verification successful${NC}"
        echo -e "${GREEN}🎉 GPG signing is now available in the container!${NC}"
        echo ""
        echo -e "${YELLOW}💡 You can now use git commit (with signing) inside the container${NC}"
        echo -e "${YELLOW}📝 The key will be removed when the container stops${NC}"
    fi
else
    if [[ "$SILENT" != "true" ]]; then
        echo -e "${RED}❌ Key verification failed${NC}"
    fi
    exit 1
fi