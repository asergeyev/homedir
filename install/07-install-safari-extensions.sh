#!/usr/bin/env bash
# 07-install-safari-extensions.sh [--all] — Ask about each Safari extension and install the ones you pick from the Mac
# App Store (through mas; sign in to the App Store app first). Extensions already installed are skipped without asking;
# lines marked `off` are asked about only with --all. Safe to re-run.
set -euo pipefail
. "$(dirname "$0")/../lib/funcs.sh"
parse_flags "$@"
need_terminal

mas_app 1569813296 "1Password for Safari" "fills logins from 1Password"
mas_app 6720708363 "Obsidian Web Clipper" "saves pages to the vault"
mas_app 6504861501 "Ghostery" "ad and tracker blocker" "Ghostery AdBlocker for Privacy"
off mas_app 1511935951 "BetterJSON" "JSON viewer"
off mas_app 1445328303 "PrettyJSON for Safari" "JSON viewer"
mas_app 1521133201 "Speed Player" "video playback speed"

echo "Turn new extensions on in Safari > Settings > Extensions."
report_off
report_failed
