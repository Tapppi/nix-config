#!/bin/sh

# Helper to run commands with indented output
run_step() {
  echo "› $1"
  shift
  { "$@" 2>&1 | sed 's/^/    /'; } || {
    echo "✖ Command failed: $*" >&2
    exit 1
  }
  echo
}

echo "==> Installing Xcode Command Line Tools (if needed)..."
run_step "xcode-select --install" xcode-select --install || true  # May already be installed

set -euo pipefail

echo "==> Installing Nix via Determinate Systems..."
run_step "curl | sh" \
  sh -c 'curl --proto "=https" --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm'

REPO_DIR=~/project/github/tapppi/nix-config
PARENT_DIR=$(dirname "$REPO_DIR")

if [ -d "$REPO_DIR" ]; then
  echo "==> nix-config repo exists, pulling latest changes..."
  run_step "git -C \"$REPO_DIR\" pull" git -C "$REPO_DIR" pull
else
  echo "==> nix-config repo not found, cloning..."
  run_step "mkdir -p \"$PARENT_DIR\"" mkdir -p "$PARENT_DIR"
  run_step "git clone" git clone https://github.com/tapppi/nix-config.git "$REPO_DIR"
fi

echo "==> Entering nix-config directory..."
cd "$REPO_DIR"

echo "==> Building configuration with nix run .#build..."
run_step "nix run .#build" nix run .#build

echo "✓ Build complete."
echo
echo "👉 To apply the configuration, run manually:"
echo "   nix run .#build-switch"