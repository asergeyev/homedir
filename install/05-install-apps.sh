#!/usr/bin/env bash
# 05-install-apps.sh — Install the GUI apps every reinstall gets, straight from the vendors (no Brew, no questions).
# The rest are optional: 06-install-optional-apps.sh and 07-install-safari-extensions.sh ask about each one.
# One app failing doesn't stop the rest; failures are listed at the end and the script exits 1.
set -euo pipefail
. "$(dirname "$0")/../lib/funcs.sh"

try_install install_zip_app "Visual Studio Code" "https://update.code.visualstudio.com/latest/darwin-arm64/stable"
# 1Password is installed by hand in README step 2: GitHub SSH needs its agent before homedir is cloned
try_install install_zip_app "iTerm" "https://iterm2.com/downloads/stable/latest"
try_install install_dmg_app "Obsidian" "$(gh_asset_url 'obsidianmd/obsidian-releases' '^Obsidian-[0-9.]+\.dmg$')"
try_install install_zip_app "Claude" "$(claude_zip_url)"
try_install install_dmg_app "Antigravity" "$(antigravity_dmg_url)"
try_install install_dmg_app "Slack" "https://slack.com/ssb/download-osx-silicon"
try_install install_dmg_app "Signal" "https://updates.signal.org/desktop/signal-desktop-mac-arm64.dmg"

echo ""
echo "By hand (download portal only): OrbStack.app from https://orbstack.dev"
echo ""
echo "Next: ./install/06-install-optional-apps.sh and ./install/07-install-safari-extensions.sh ask about the"
echo "optional apps; then OrbStack (README step 3)."
report_failed
