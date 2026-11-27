#!/usr/bin/env bash
# 90-optional-setup-lima.sh — Fallback if switching back from OrbStack to Lima (quit and delete OrbStack.app first).
# Installs Lima (Darwin arm64 tarball) + standalone Docker CLI/plugins, links homedir's Lima templates, creates
# `docker`, `clickhouse`, `dev`, links the host shims for dev's infra CLIs (lib/link-vm-shims.sh) and points
# DOCKER_HOST in ~/.zprofile at the `docker` VM. Safe to re-run.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"
mkdir -p "$HOME/.local/bin" "$HOME/.local/share" "$HOME/.docker/cli-plugins" "$HOME/.lima/_templates"

if ! command -v limactl >/dev/null 2>&1; then
  echo "==> Installing Lima (standalone Darwin arm64 release)..."
  lima_url=$(curl -fsSL https://api.github.com/repos/lima-vm/lima/releases/latest \
    | jq -r '.assets[] | select(.name | test("^lima-[0-9.]+-Darwin-arm64\\.tar\\.gz$")) | .browser_download_url')
  tmp=$(mktemp -d)
  curl -fsSL "$lima_url" -o "$tmp/lima.tgz"
  tar -C "$HOME/.local" -xzf "$tmp/lima.tgz"
  rm -rf "$tmp"
fi

if ! command -v docker >/dev/null 2>&1; then
  docker_tgz=$(curl -fsSL https://download.docker.com/mac/static/stable/aarch64/ \
    | grep -oE 'docker-[0-9.]+\.tgz' | sort -V | tail -n 1)
  tmp=$(mktemp -d)
  curl -fsSL "https://download.docker.com/mac/static/stable/aarch64/${docker_tgz}" -o "$tmp/docker.tgz"
  tar -C "$tmp" -xzf "$tmp/docker.tgz"
  install -m 0755 "$tmp/docker/docker" "$HOME/.local/bin/docker"
  rm -rf "$tmp"
fi

# A deleted OrbStack.app leaves its plugin links here; drop them, or the downloads below write through them and fail
for p in docker-compose docker-buildx; do
  if [ -L "$HOME/.docker/cli-plugins/$p" ] && [ ! -e "$HOME/.docker/cli-plugins/$p" ]; then
    rm "$HOME/.docker/cli-plugins/$p"
  fi
done

if [ ! -x "$HOME/.docker/cli-plugins/docker-compose" ]; then
  compose_url=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest \
    | jq -r '.assets[] | select(.name == "docker-compose-darwin-aarch64") | .browser_download_url')
  curl -fsSL "$compose_url" -o "$HOME/.docker/cli-plugins/docker-compose"
  chmod +x "$HOME/.docker/cli-plugins/docker-compose"
fi

if [ ! -x "$HOME/.docker/cli-plugins/docker-buildx" ]; then
  buildx_url=$(curl -fsSL https://api.github.com/repos/docker/buildx/releases/latest \
    | jq -r '.assets[] | select(.name | test("^buildx-v[0-9.]+\\.darwin-arm64$")) | .browser_download_url')
  curl -fsSL "$buildx_url" -o "$HOME/.docker/cli-plugins/docker-buildx"
  chmod +x "$HOME/.docker/cli-plugins/docker-buildx"
fi

# `template://<name>` reads ~/.lima/_templates; they stay links into this checkout (a file in the way is kept as .bak)
echo "==> Linking Lima templates..."
for f in "$SRC/conf/lima/_templates/"*.yaml; do
  [ -f "$f" ] || continue
  dst="$HOME/.lima/_templates/$(basename "$f")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  ln -sfn "$f" "$dst"
done

ensure_vm() {
  local name=$1
  if limactl list --json 2>/dev/null | jq -e "select(.name==\"$name\")" >/dev/null 2>&1; then
    echo "==> Lima VM '$name' already exists."
  else
    echo "==> Creating Lima VM '$name' from template://$name..."
    limactl create --tty=false --name="$name" "template://$name"
  fi
}

ensure_vm docker
ensure_vm clickhouse
ensure_vm dev

limactl start --tty=false docker
limactl start --tty=false dev

# Host links to the dev VM's infra CLIs
"$SRC/lib/link-vm-shims.sh"

# The Docker CLI talks to the `docker` VM; $HOME stays literal so the shell expands it
line='export DOCKER_HOST="unix://$HOME/.lima/docker/sock/docker.sock"'
if ! grep -qxF "$line" "$HOME/.zprofile" 2>/dev/null; then
  echo "==> Pointing DOCKER_HOST at the Lima docker VM in ~/.zprofile..."
  printf '\n# Docker CLI -> the Lima `docker` VM (install/90-optional-setup-lima.sh)\n%s\n' "$line" >>"$HOME/.zprofile"
fi

echo "Lima fallback ready. Open a new shell so DOCKER_HOST applies."
