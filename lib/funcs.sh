# shellcheck shell=bash
# funcs.sh — Helpers the app installers (install/05, 06, 07 and 09) source: vendor downloads, Mac App Store installs
# through mas, a y/N question per optional app, and --all for the apps marked off. Not run on its own.

# /usr/local/bin last: the mas .pkg installs there
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$PATH:/usr/local/bin"
# Where apps go and where "already installed" is checked; a test can point it at an empty folder
APPS_DIR=${APPS_DIR:-/Applications}
FAILED=()
MAS_READY=0
# --all (parse_flags) sets ASK_OFF=1; without it, off() lists the apps it skipped in OFF
ASK_OFF=0
OFF=()

# Installers run in a `||` context (see try_install), where `set -e` is off, so each checks its own steps.
install_zip_app() {
  local app_name=$1 url=$2 tmp found rc=0
  if [ -d "$APPS_DIR/${app_name}.app" ]; then
    echo "==> Already installed: ${app_name}"
    return 0
  fi
  [ -n "$url" ] || { echo "Skipping ${app_name}: empty download URL" >&2; return 1; }
  echo "==> Installing ${app_name} (zip)..."
  tmp=$(mktemp -d) || return 1
  if curl -fL "$url" -o "$tmp/app.zip" && ditto -xk "$tmp/app.zip" "$tmp/out"; then
    found=$(find "$tmp/out" -maxdepth 2 -name "*.app" | head -n 1)
    if [ -n "$found" ]; then
      cp -R "$found" "$APPS_DIR/" || rc=$?
    else
      echo "No .app found in $url" >&2
      rc=1
    fi
  else
    rc=1
  fi
  rm -rf "$tmp"
  return "$rc"
}

install_dmg_app() {
  local app_name=$1 url=$2 tmp mnt found rc=0
  if [ -d "$APPS_DIR/${app_name}.app" ]; then
    echo "==> Already installed: ${app_name}"
    return 0
  fi
  [ -n "$url" ] || { echo "Skipping ${app_name}: empty download URL" >&2; return 1; }
  echo "==> Installing ${app_name} (dmg)..."
  tmp=$(mktemp -d) || return 1
  mnt=$(mktemp -d) || { rm -rf "$tmp"; return 1; }
  if ! curl -fL "$url" -o "$tmp/app.dmg"; then
    rm -rf "$tmp" "$mnt"
    return 1
  fi
  # `yes` accepts license prompts; without pipefail its SIGPIPE exit doesn't count, only hdiutil's
  set +o pipefail
  yes | hdiutil attach "$tmp/app.dmg" -mountpoint "$mnt" -nobrowse -quiet >/dev/null || rc=$?
  set -o pipefail
  if [ "$rc" -ne 0 ]; then
    rm -rf "$tmp" "$mnt"
    return "$rc"
  fi
  found=$(find "$mnt" -maxdepth 2 -name "*.app" | head -n 1)
  if [ -n "$found" ]; then
    cp -R "$found" "$APPS_DIR/" || rc=$?
  else
    echo "No .app found in $url" >&2
    rc=1
  fi
  hdiutil detach "$mnt" -quiet || hdiutil detach "$mnt" -force -quiet || true
  rm -rf "$tmp" "$mnt"
  return "$rc"
}

install_pkg_app() {
  local app_name=$1 url=$2 tmp rc=0
  if [ -d "$APPS_DIR/${app_name}.app" ]; then
    echo "==> Already installed: ${app_name}"
    return 0
  fi
  [ -n "$url" ] || { echo "Skipping ${app_name}: empty download URL" >&2; return 1; }
  echo "==> Installing ${app_name} (pkg)..."
  tmp=$(mktemp -d) || return 1
  if curl -fL "$url" -o "$tmp/app.pkg"; then
    sudo installer -pkg "$tmp/app.pkg" -target / || rc=$?
  else
    rc=1
  fi
  rm -rf "$tmp"
  return "$rc"
}

# jq regexes: single-quoted shell strings, so a literal dot is `\.` (`\\.` would match a backslash)
gh_asset_url() {
  local repo=$1 regex=$2
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" \
    | jq -r --arg re "$regex" '.assets[] | select(.name | test($re)) | .browser_download_url' \
    | head -n 1
}

# Claude desktop ships as a universal zip; its auto-update feed names the current one (claude.ai/download is HTML).
claude_zip_url() {
  curl -fsSL "https://downloads.claude.ai/releases/darwin/universal/RELEASES.json" \
    | jq -r '.currentRelease as $v | .releases[] | select(.version == $v) | .updateTo.url' \
    | head -n 1
}

# Antigravity's download page links a versioned dmg of the desktop app ("Antigravity IDE.dmg" is a different app).
antigravity_dmg_url() {
  curl -fsSL "https://antigravity.google/download" \
    | grep -oE 'https://[^"]+/antigravity-hub/[^"]+/darwin-arm/Antigravity\.dmg' \
    | head -n 1
}

# try_install <installer> <app name> <url>: install one app; on failure record it and carry on.
try_install() {
  "$@" || FAILED+=("$2")
}

# report_failed: list the apps that failed and return 1, so a script ending with it exits 1.
report_failed() {
  [ "${#FAILED[@]}" -gt 0 ] || return 0
  echo "" >&2
  echo "FAILED (${#FAILED[@]}): ${FAILED[*]}" >&2
  return 1
}

# parse_flags "$@": the optional installers take one flag, --all, which also asks about the apps marked off.
parse_flags() {
  case "$*" in
    "") ;;
    --all) ASK_OFF=1 ;;
    *) echo "usage: $(basename "$0") [--all]   (--all also asks about the apps marked off)" >&2; exit 2 ;;
  esac
}

# off <helper> <args>...: one mas_app or page line that's off for now; it runs only with --all.
off() {
  if [ "$ASK_OFF" = 1 ]; then
    "$@"
  else
    case "$1" in mas_app) OFF+=("$3") ;; *) OFF+=("$2") ;; esac
  fi
}

# report_off: name the apps skipped as off, so they're easy to bring back.
report_off() {
  local list
  [ "${#OFF[@]}" -gt 0 ] || return 0
  printf -v list '%s, ' "${OFF[@]}"
  echo "Off, asked about only with --all: ${list%, }"
}

# need_terminal: the optional installers ask about each app, so someone has to be there to answer.
need_terminal() {
  [ -t 0 ] || { echo "$(basename "$0") asks about each app: run it in a terminal." >&2; exit 2; }
}

# installed <.app name>: whether it's in $APPS_DIR. The name may be a glob, for apps named by year
# ("Adobe Photoshop */Adobe Photoshop *"); IFS is empty so a name with spaces stays one word.
installed() {
  local IFS='' p
  for p in "$APPS_DIR"/$1.app; do
    [ -d "$p" ] && return 0
  done
  return 1
}

# want <name> <what it is> [<.app name, default name>]: 0 when the app isn't installed and you answer y.
want() {
  local app=${3:-$1} reply
  if installed "$app"; then
    echo "==> Already installed: $1"
    return 1
  fi
  read -r -p "Install $1 ($2)? [y/N] " reply || { echo; return 1; }
  case "$reply" in [yY]*) return 0 ;; *) return 1 ;; esac
}

# ensure_mas: install mas from GitHub Releases the first time an App Store app is picked.
ensure_mas() {
  local url tmp rc=0
  [ "$MAS_READY" = 0 ] || return 0
  if ! command -v mas >/dev/null 2>&1; then
    echo "==> Installing mas from GitHub Releases (.pkg)..."
    url=$(gh_asset_url 'mas-cli/mas' '^mas-[0-9.]+-arm64\.pkg$')
    [ -n "$url" ] || { echo "No arm64 .pkg in mas's latest release" >&2; return 1; }
    tmp=$(mktemp -d) || return 1
    if curl -fsSL "$url" -o "$tmp/mas.pkg"; then
      sudo installer -pkg "$tmp/mas.pkg" -target / || rc=$?
    else
      rc=1
    fi
    rm -rf "$tmp"
    [ "$rc" -eq 0 ] || return "$rc"
  fi
  echo "    (mas installs with the account signed in to the App Store app)"
  MAS_READY=1
}

# mas_app <App Store id> <name> <what it is> [<.app name>]: ask, then install it through mas.
mas_app() {
  want "$2" "$3" "${4:-$2}" || return 0
  ensure_mas || { FAILED+=("$2"); return 0; }
  echo "==> Installing via mas: $2 ($1)..."
  mas install "$1" || FAILED+=("$2")
}

# page <name> <what it is> <download page> [<.app name>]: for apps with no direct download, ask, then open the page.
page() {
  want "$1" "$2" "${4:-$1}" || return 0
  echo "    opening $3: install it from there"
  open "$3" || FAILED+=("$1")
}
