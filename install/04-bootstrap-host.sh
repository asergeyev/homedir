#!/usr/bin/env bash
# 04-bootstrap-host.sh [--upgrade] — Install host toolchain with ZERO Homebrew (Apple Silicon, Option A + OrbStack).
# Installs: mise (+ Go, Node, pnpm, uv, delta, gh, glab, jq, oasdiff, rg, shellcheck, yq, mc), Python via uv,
# ClickHouse client, Claude Code and Antigravity CLIs, Go dev tools (gopls, gofumpt, golangci-lint-v2, dlv, garble,
# protoc-gen-go, docker-credential-ecr-login, plus the private ones ~/.zprofile-work lists), and Fira Code font.
# (Docker CLI, compose, and buildx come bundled with OrbStack.app.)
# --upgrade also brings what is already installed to its newest version: mise and its tools, the uv Pythons' patch
# releases, the ClickHouse client and the two CLIs. The Go tools always reinstall at @latest.
set -euo pipefail

UPGRADE=0
case "${1:-}" in
  '') ;;
  --upgrade) UPGRADE=1 ;;
  *) echo "Usage: $(basename "$0") [--upgrade]" >&2; exit 2 ;;
esac

[ "$(uname -m)" = "arm64" ] || { echo "Expected arm64 Apple Silicon Mac" >&2; exit 1; }
xcode-select -p >/dev/null 2>&1 || { echo "Run 'xcode-select --install' first." >&2; exit 1; }

mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/go/bin" "$HOME/Library/Fonts"
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/go/bin:$PATH"
# Go tools land in ~/go/bin; a set GOBIN also keeps mise from pointing it at the per-version Go dir
export GOBIN="$HOME/go/bin"

echo "==> 1/6 Installing mise..."
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
elif [ "$UPGRADE" = 1 ]; then
  mise self-update --yes || echo "WARN: mise didn't update itself" >&2
fi

echo "==> 2/6 Installing mise tools from ~/.config/mise/config.toml..."
# One tool failing (say conda:mc) shouldn't stop the rest; a missing go or uv still fails the steps below
mise install --yes || echo "WARN: some mise tools failed to install; fix them and run 'mise install' again" >&2
# Within each version in the config: go = "1" moves to the newest 1.x, node = "24" to the newest 24.x
if [ "$UPGRADE" = 1 ]; then
  mise upgrade || echo "WARN: some mise tools failed to upgrade; fix them and run 'mise upgrade' again" >&2
fi

echo "==> 3/6 Installing Python via uv: the newest (default python3/python in ~/.local/bin) and 3.12..."
# The newest is python3 for Claude hooks (otherwise the Xcode CLT 3.9) and uv's pick without a pin, since uv prefers
# the newest managed Python. 3.12 is for clients of the irregular CA (our ClickHouse, the ClickHouse MCP): 3.13+ reject
# it (basicConstraints not critical), so they run with `uv run --python 3.12 …`. Other versions download on first use.
# --default is experimental but needs no --preview.
uv python install --default
uv python install 3.12
# Each installed minor to its newest patch, not to a new minor
if [ "$UPGRADE" = 1 ]; then uv python upgrade || echo "WARN: uv didn't upgrade the Pythons" >&2; fi

echo "==> 4/6 Installing ClickHouse client (standalone macOS binary)..."
if [ "$UPGRADE" = 1 ] || ! command -v clickhouse >/dev/null 2>&1; then
  tmp=$(mktemp -d)
  (cd "$tmp" && curl -fsSL https://clickhouse.com/ | sh)
  install -m 0755 "$tmp/clickhouse" "$HOME/.local/bin/clickhouse"
  rm -rf "$tmp"
fi

echo "==> 5/6 Installing Go tools (latest, like Go itself)..."
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/gopls@latest
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
mv -f "$HOME/go/bin/golangci-lint" "$HOME/go/bin/golangci-lint-v2"
go install github.com/go-delve/delve/cmd/dlv@latest
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
go install mvdan.cc/garble@latest
# Docker's credsStore (set by 10-setup-orbstack.sh): ECR tokens from the AWS profile, no docker login or keychain
go install github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login@latest
# Private Go tools from your work settings, restored with the SSH keys in README step 2: ~/.zprofile-work lists them in
# GO_WORK_TOOLS and sets their GOPRIVATE, and ~/.config/git/config-work rewrites their URLs to SSH
if [ -f "$HOME/.zprofile-work" ]; then
  # shellcheck source=/dev/null
  . "$HOME/.zprofile-work"
  for tool in ${GO_WORK_TOOLS:-}; do
    go install "$tool"
  done
fi

echo "==> 6/6 Installing the Claude Code and Antigravity CLIs and Fira Code font..."
if ! command -v claude >/dev/null 2>&1; then
  curl -fsSL https://claude.ai/install.sh | bash
elif [ "$UPGRADE" = 1 ]; then
  claude update || echo "WARN: claude didn't update" >&2
fi
# agy lands in ~/.local/bin; the installer then runs `agy install`, which sets up the shell
if ! command -v agy >/dev/null 2>&1; then
  curl -fsSL https://antigravity.google/cli/install.sh | bash
elif [ "$UPGRADE" = 1 ]; then
  agy update || echo "WARN: agy didn't update" >&2
fi

if ! ls "$HOME/Library/Fonts"/FiraCode*.ttf >/dev/null 2>&1; then
  fira_url=$(curl -fsSL https://api.github.com/repos/tonsky/FiraCode/releases/latest \
    | jq -r '.assets[] | select(.name | test("^Fira_Code_v.*\\.zip$")) | .browser_download_url')
  tmp=$(mktemp -d)
  curl -fsSL "$fira_url" -o "$tmp/firacode.zip"
  unzip -q "$tmp/firacode.zip" -d "$tmp/fira"
  cp "$tmp"/fira/ttf/*.ttf "$HOME/Library/Fonts/"
  rm -rf "$tmp"
fi

if [ "$UPGRADE" = 1 ]; then
  echo "Upgrade complete. Run homedir-prune to clear the old versions and caches."
else
  echo "Host bootstrap complete. Next: the GUI apps (./install/05-install-apps.sh, then the optional 06 and 07;" \
    "README step 3)"
fi
