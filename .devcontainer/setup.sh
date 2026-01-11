#!/bin/bash
set -e

# Install Posit Air CLI
echo "Installing Posit Air CLI..."
curl -LsSf https://github.com/posit-dev/air/releases/latest/download/air-installer.sh | sh

# Add air to PATH for the current script execution if needed (though we add it to remoteEnv in devcontainer.json)
# The installer typically puts it in ~/.local/bin
export PATH="$HOME/.local/bin:$PATH"

# Install R dependencies
echo "Installing R dependencies (excluding rJava)..."
Rscript .devcontainer/setup.R

echo "Setup complete!"
