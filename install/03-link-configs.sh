#!/usr/bin/env bash
# 03-link-configs.sh — Symlink homedir scripts, Claude Code's hooks and the xbar plugin, and copy each tool config in
# conf/configs.txt where there is none yet. From then on the config is yours: bin/homedir-sync compares the `sync`
# ones with this checkout, and --reset TOOL overwrites yours with homedir's copy.
set -euo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
CONFIGS="$SRC/conf/configs.txt"
# The copy each `sync` config had at its last sync, so bin/homedir-sync can tell which side changed
BASE="$HOME/.local/state/homedir/base"

# tools: the tool names conf/configs.txt lists
tools() { sed -n 's/^[a-z][a-z]* \([a-z][a-z0-9-]*\) .*/\1/p' "$CONFIGS" | uniq; }

usage() {
  cat <<EOF
Usage: $(basename "$0") [--reset TOOL,...]
  --reset TOOLS  overwrite these configs with homedir's copy: your changes are gone, the old file stays as
                 <file>.bak.<time> (tools: $(tools | xargs))
EOF
}

RESET=
while [ $# -gt 0 ]; do
  case "$1" in
    --reset) RESET=${2:?--reset needs a tool list}; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done
for t in $(printf '%s' "$RESET" | tr ',' ' '); do
  tools | grep -qx "$t" || { echo "Unknown tool: $t (known: $(tools | xargs))" >&2; exit 2; }
done

# install_config MODE DEF DST: copy homedir's DEF to ~/DST, and remember it as the last sync of a `sync` config
install_config() {
  mkdir -p "$(dirname "$HOME/$3")"
  cp "$SRC/$2" "$HOME/$3"
  if [ "$1" = sync ]; then
    mkdir -p "$(dirname "$BASE/$3")"
    (umask 077 && cp "$SRC/$2" "$BASE/$3")
  fi
}

if [ -n "$RESET" ]; then
  stamp=$(date +%Y%m%d%H%M%S)
  while read -r mode tool def dst; do
    case "$mode" in ''|'#'*) continue ;; esac
    case ",$RESET," in *",$tool,"*) ;; *) continue ;; esac
    if [ -e "$HOME/$dst" ] || [ -L "$HOME/$dst" ]; then
      mv "$HOME/$dst" "$HOME/$dst.bak.$stamp"
      echo "    kept the old one as ~/$dst.bak.$stamp"
    fi
    install_config "$mode" "$def" "$dst"
    echo "==> $tool: ~/$dst is homedir's copy again"
  done <"$CONFIGS"
  exit 0
fi

link() {
  local src=$1 dst=$2
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  ln -sfn "$src" "$dst"
}

# Links to a script bin/ no longer has (renamed or removed) would otherwise stay behind, broken
for l in "$HOME/.local/bin/"* "$HOME/.claude/hooks/"*; do
  if [ -L "$l" ] && [ ! -e "$l" ]; then
    case "$(readlink "$l")" in
      "$SRC/bin/"*) rm "$l" && echo "==> Removed ~/${l#"$HOME"/}: links to a script homedir no longer has" ;;
    esac
  fi
done

echo "==> Linking bin/ -> ~/.local/bin..."
mkdir -p "$HOME/.local/bin"
for f in "$SRC/bin/"*; do
  [ -f "$f" ] || continue
  chmod +x "$f"
  link "$f" "$HOME/.local/bin/$(basename "$f")"
done
echo "==> Linking bin/agentic -> ~/.claude/hooks (Claude Code's Bash hooks, run by settings.json)..."
mkdir -p "$HOME/.claude/hooks"
for f in "$SRC/bin/agentic/"*; do
  [ -f "$f" ] || continue
  chmod +x "$f"
  link "$f" "$HOME/.claude/hooks/$(basename "$f")"
done

# The dev-VM CLI shims come later: lib/link-vm-shims.sh, run by 10-setup-orbstack.sh once OrbStack is in

echo "==> Copying tool configs where there is none yet (an existing one is yours and stays)..."
while read -r mode tool def dst; do
  case "$mode" in ''|'#'*) continue ;; esac
  if [ -e "$HOME/$dst" ] || [ -L "$HOME/$dst" ]; then
    echo "    keep ~/$dst"
  else
    install_config "$mode" "$def" "$dst"
    echo "    $tool: ~/$dst"
  fi
done <"$CONFIGS"

echo "==> Linking xbar plugin..."
chmod +x "$SRC/conf/xbar/projects-latest-tags.15m.sh"
link "$SRC/conf/xbar/projects-latest-tags.15m.sh" \
  "$HOME/Library/Application Support/xbar/plugins/projects-latest-tags.15m.sh"

echo "Done. Compare your configs with this checkout: homedir-sync."
echo "Start one over (your changes are lost): $0 --reset TOOL"
