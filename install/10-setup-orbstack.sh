#!/usr/bin/env bash
# 10-setup-orbstack.sh — Create and provision the OrbStack `dev` and `clickhouse` Ubuntu machines, and link the
# host shims for the dev machine's infra CLIs (lib/link-vm-shims.sh).
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"

command -v orbctl >/dev/null 2>&1 || {
  echo "OrbStack CLI ('orbctl') not found. Install OrbStack from https://orbstack.dev first." >&2
  exit 1
}

echo "==> Starting OrbStack..."
orbctl start

# OrbStack's own settings aren't in the backup: one 20 GiB limit shared by Docker and the machines, and no start at
# login. A new memory limit applies only after a restart, which stops every container and machine.
orbctl config set app.start_at_login false
if ! orbctl config show | grep -qx 'memory_mib: 20000'; then
  echo "==> Setting OrbStack's memory limit to 20 GB and restarting it..."
  orbctl config set memory_mib 20000
  orbctl stop
  orbctl start
fi

# Registry credentials via docker-credential-ecr-login (04-bootstrap-host.sh), for every registry so none is named:
# ECR tokens come from the AWS profile; other registries pull anonymously and `docker login` can't store a login
cfg="$HOME/.docker/config.json"
if [ "$(jq -r '.credsStore // empty' "$cfg" 2>/dev/null)" != ecr-login ]; then
  echo "==> Setting docker credsStore to ecr-login..."
  mkdir -p "$HOME/.docker"
  [ -s "$cfg" ] || echo '{}' >"$cfg"
  jq '.credsStore = "ecr-login"' "$cfg" >"$cfg.new" && mv "$cfg.new" "$cfg" && chmod 600 "$cfg"
fi

ensure_machine() {
  local name=$1
  if orbctl list -q | grep -qx "$name"; then
    echo "==> OrbStack machine '$name' already exists."
  else
    echo "==> Creating OrbStack Ubuntu machine '$name'..."
    orbctl create ubuntu "$name"
  fi
}

ensure_machine dev
orb -m dev bash -s <"$SRC/conf/orbstack/provision-dev.sh"
# Host links to the dev VM's infra CLIs, now that OrbStack's own (kubectl) are on the host and win
"$SRC/lib/link-vm-shims.sh"

ensure_machine clickhouse
orb -m clickhouse bash -s <"$SRC/conf/orbstack/provision-clickhouse.sh"

echo "==> Stopping 'clickhouse' until needed (start anytime with: orbctl start clickhouse)..."
orbctl stop clickhouse

echo "OrbStack machines ready."
echo "  Docker:      available natively on host (docker / docker compose / docker buildx)"
echo "  Dev toolbox: dev   (or: dev aws s3 ls, tf, ansible-playbook, helm, ...; kubectl is OrbStack's, on the host)"
echo "  ClickHouse:  orbctl start clickhouse  ->  clickhouse client --port 39000"
echo "               (always pass the port: a bare client tries 9000, compose stacks, then 9440, the prod forward)"
