#!/bin/bash
set -e

# Install Posit Air CLI
echo "Installing Posit Air CLI..."
# Using the installer script from the latest release.
# In a production environment, you might want to pin this to a specific version or check a signature.
curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh

# Ensure air is on PATH for the remainder of this setup script.
# The installer typically puts it in ~/.local/bin; remoteEnv in devcontainer.json
# will add this directory to PATH for future shells after setup completes.
export PATH="$HOME/.local/bin:$PATH"

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
