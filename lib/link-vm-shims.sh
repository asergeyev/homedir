#!/usr/bin/env bash
# link-vm-shims.sh — Point each infra CLI that lives in the `dev` VM and is missing on the host at bin/vm-shim
# (~/.local/bin/<cmd>), so scripts, make, hooks and Claude Code find it. install/10-setup-orbstack.sh and
# install/90-optional-setup-lima.sh run it once the VM exists, so CLIs the VM app puts on the host count first.
# Safe to re-run.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
SHIM="$SRC/bin/vm-shim"
# Not kubectl: OrbStack installs the host's, and `dev kubectl` runs the VM's.
VM_CMDS="aws terraform tf terragrunt ansible ansible-playbook ansible-vault ansible-galaxy k9s helm trivy nmap iperf3"

# real_cmd_on_path <cmd>: print the first <cmd> in ~/.local/bin or on PATH that isn't a vm-shim link;
# fail if there is none.
real_cmd_on_path() {
  local cmd=$1 dir
  local IFS=:
  for dir in $HOME/.local/bin:$PATH; do
    [ -n "$dir" ] && [ -x "$dir/$cmd" ] && [ ! -d "$dir/$cmd" ] || continue
    case "$(readlink "$dir/$cmd" 2>/dev/null || true)" in
      */vm-shim) continue ;;
    esac
    echo "$dir/$cmd"
    return 0
  done
  return 1
}

echo "==> Linking VM shims for infra CLIs missing on the host..."
mkdir -p "$HOME/.local/bin"
for cmd in $VM_CMDS; do
  dst="$HOME/.local/bin/$cmd"
  if real=$(real_cmd_on_path "$cmd"); then
    # A real binary exists: drop a stale shim of ours so it can't shadow that binary
    case "$(readlink "$dst" 2>/dev/null || true)" in
      */vm-shim) rm "$dst" ;;
    esac
    echo "    skip $cmd (host has $real)"
    continue
  fi
  # A non-link file in the way is kept as <name>.bak.<time>
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
  fi
  ln -sfn "$SHIM" "$dst"
done
