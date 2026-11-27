#!/usr/bin/env bash
# provision-dev.sh — Idempotently provision the OrbStack `dev` Ubuntu toolbox machine.
set -euo pipefail

# sudo drops an exported DEBIAN_FRONTEND, so pass it through env on every apt-get
apt_get() { sudo env DEBIAN_FRONTEND=noninteractive apt-get "$@"; }

# Mac home, shared into the machine at the same path (the OrbStack user is named after the macOS user)
MAC_HOME=${MAC_HOME:-/Users/$(id -un)}

# Global Terraform/Terragrunt = what most ~/projects/TF repos pin (.terraform-version, CI images);
# a repo's own .terraform-version / .terragrunt-version wins via mise idiomatic version files.
TERRAFORM_VERSION=1.14.3
TERRAGRUNT_VERSION=1.0.3

echo "==> Installing system CLI packages..."
apt_get update
apt_get install -y \
  ca-certificates curl dnsutils git gnupg htop iperf3 jq \
  mc nmap unzip xz-utils

# link_mac_path <path relative to home>: link the VM-home path to the Mac copy if that exists.
# Never replaces an existing VM path; for a real VM directory it links only the entries missing there.
link_mac_path() {
  local src="$MAC_HOME/$1" dst="$HOME/$1" entry name
  [ -e "$src" ] || return 0
  if [ ! -e "$dst" ] && [ ! -L "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    echo "    $dst -> $src"
  elif [ -d "$dst" ] && [ ! -L "$dst" ] && [ -d "$src" ]; then
    for entry in "$src"/* "$src"/.[!.]*; do
      [ -e "$entry" ] || continue
      name=$(basename "$entry")
      if [ ! -e "$dst/$name" ] && [ ! -L "$dst/$name" ]; then
        ln -s "$entry" "$dst/$name"
        echo "    $dst/$name -> $entry"
      fi
    done
  fi
}

if [ -d "$MAC_HOME" ]; then
  # The VM's $HOME is /home/<user>, not the Mac home. iac ansible.cfg needs ~/.ssh/ansible.pem (via .ssh);
  # its vault_password_file is repo-relative (same path here) and control_path_dir stays VM-local.
  echo "==> Linking Mac-home configs into $HOME..."
  for p in .aws .kube .ssh .s3cfg .config/gh .config/glab-cli; do
    link_mac_path "$p"
  done

  # Every CA (PEM, *.crt) in the Mac's ~/.config/ca-certificates into the system trust store (curl, git, apt, tools
  # using the system bundle), mirrored: a CA removed on the Mac leaves the VM too
  ca_src="$MAC_HOME/.config/ca-certificates"
  ca_dst=/usr/local/share/ca-certificates/mac-home
  ca_changed=""
  sudo mkdir -p "$ca_dst"
  for src in "$ca_src"/*.crt; do
    [ -f "$src" ] || continue
    if ! cmp -s "$src" "$ca_dst/${src##*/}"; then
      sudo install -m 0644 "$src" "$ca_dst/${src##*/}"
      ca_changed=1
    fi
  done
  for dst in "$ca_dst"/*.crt; do
    [ -f "$dst" ] || continue
    if [ ! -f "$ca_src/${dst##*/}" ]; then
      sudo rm -f "$dst"
      ca_changed=1
    fi
  done
  if [ -n "$ca_changed" ]; then
    echo "==> Updating the CA trust store from ~/.config/ca-certificates..."
    sudo update-ca-certificates --fresh
  fi
else
  echo "WARN: $MAC_HOME is not shared into this machine; skipping config links and CAs." >&2
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "==> Installing AWS CLI v2 (arm64)..."
  tmp=$(mktemp -d)
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "$tmp/awscliv2.zip"
  unzip -q "$tmp/awscliv2.zip" -d "$tmp"
  sudo "$tmp/aws/install" --update
  rm -rf "$tmp"
fi

if ! command -v trivy >/dev/null 2>&1; then
  echo "==> Installing Trivy..."
  curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
    | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/trivy.gpg
  echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main" \
    | sudo tee /etc/apt/sources.list.d/trivy.list >/dev/null
  apt_get update
  apt_get install -y trivy
fi

if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
if ! command -v mise >/dev/null 2>&1; then
  curl -fsSL https://mise.run | sh
fi

export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"

# Python 3.12: 3.13+ rejects irregular CA ("Basic Constraints of CA cert not marked critical").
# Re-running with an existing ansible on another Python makes uv rebuild its environment.
echo "==> Installing Ansible via uv (Python 3.12)..."
uv tool install --python 3.12 --with-executables-from ansible-core ansible

echo "==> Enabling .terraform-version / .terragrunt-version for mise..."
mkdir -p "$HOME/.config/mise/conf.d"
cat >"$HOME/.config/mise/conf.d/idiomatic-version-files.toml" <<'EOF'
[settings]
idiomatic_version_file_enable_tools = ["terraform", "terragrunt"]
EOF

echo "==> Installing infra CLIs via mise..."
mise use -g \
  gh@latest \
  glab@latest \
  helm@latest \
  k9s@latest \
  kubectl@latest \
  kubectx@latest \
  "terraform@$TERRAFORM_VERSION" \
  "terragrunt@$TERRAGRUNT_VERSION" \
  yq@latest

mkdir -p "$HOME/.local/bin"
ln -sf "$HOME/.local/share/mise/shims/terraform" "$HOME/.local/bin/tf"

if ! grep -q 'mise/shims' "$HOME/.profile" 2>/dev/null; then
  echo 'export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH"' >> "$HOME/.profile"
fi

echo "OrbStack 'dev' provisioning complete."
