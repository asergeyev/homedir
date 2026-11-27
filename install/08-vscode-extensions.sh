#!/usr/bin/env bash
# 08-vscode-extensions.sh — Link the VS Code `code` CLI into ~/.local/bin and install the curated extensions.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
CODE="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"

[ -x "$CODE" ] || { echo "VS Code not found in /Applications. Install it first (./install/05-install-apps.sh)." >&2; exit 1; }

echo "==> Linking ~/.local/bin/code..."
mkdir -p "$HOME/.local/bin"
ln -sfn "$CODE" "$HOME/.local/bin/code"

echo "==> Installing curated extensions from conf/vscode/extensions.txt..."
while IFS= read -r ext; do
  [ -n "$ext" ] || continue
  case "$ext" in \#*) continue ;; esac
  "$CODE" --install-extension "$ext"
done <"$SRC/conf/vscode/extensions.txt"
