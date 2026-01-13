#!/bin/bash
set -e

# Configuration
AIR_VERSION="0.8.0"
INSTALL_DIR="$HOME/.local/bin"
mkdir -p "$INSTALL_DIR"

# Detect Architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    AIR_ARCH="x86_64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    AIR_ARCH="aarch64"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

PLATFORM="unknown-linux-gnu"
FILENAME="air-${AIR_ARCH}-${PLATFORM}.tar.gz"
URL="https://github.com/posit-dev/air/releases/download/${AIR_VERSION}/${FILENAME}"

echo "Installing Posit Air CLI version ${AIR_VERSION} for ${AIR_ARCH}..."

# Download and install
# We use a temporary directory to ensure clean cleanup
TMP_DIR=$(mktemp -d)
curl -LsSf "$URL" -o "${TMP_DIR}/${FILENAME}"
tar -xzf "${TMP_DIR}/${FILENAME}" -C "$TMP_DIR"
mv "${TMP_DIR}/air" "$INSTALL_DIR/air"
rm -rf "$TMP_DIR"

# Ensure air is on PATH for the remainder of this setup script.
export PATH="$INSTALL_DIR:$PATH"

# Verify Air CLI installation
if ! command -v air &> /dev/null; then
    echo "Error: Air CLI failed to install or is not in PATH."
    exit 1
fi
echo "Air CLI installed successfully: $(air --version)"

# Install R dependencies
echo "Installing R dependencies (excluding rJava)..."
Rscript .devcontainer/setup.R

echo "Setup complete!"
