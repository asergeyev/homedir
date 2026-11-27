#!/usr/bin/env bash
# 06-install-optional-apps.sh [--all] — Ask about each optional GUI app and install the ones you pick: vendor
# downloads, Mac App Store apps (through mas; sign in to the App Store app first), and the download page for apps with
# no direct link. Apps already installed are skipped without asking; lines marked `off` are asked about only with
# --all. Safe to re-run.
set -euo pipefail
. "$(dirname "$0")/../lib/funcs.sh"
parse_flags "$@"
need_terminal

echo "==> Productivity"
off mas_app 966085870 "TickTick" "tasks"
want "Notion" "notes and docs" &&
  try_install install_dmg_app "Notion" "https://desktop-app.notion-static.com/Notion-arm64.dmg"
want "Linear" "issue tracker" && try_install install_dmg_app "Linear" "https://desktop.linear.app/mac/dmg"

echo "==> Dev and networking"
want "Insomnia" "API client" &&
  try_install install_dmg_app "Insomnia" "$(gh_asset_url 'Kong/insomnia' '^Insomnia\.Core-[0-9.]+\.dmg$')"
want "xbar" "menu bar plugins; 03 already linked the Git tags one" &&
  try_install install_dmg_app "xbar" "$(gh_asset_url 'matryer/xbar' '^xbar\.v.*\.dmg$')"
page "Zed" "secondary editor" "https://zed.dev/download"
want "Wireshark" "packet inspection" &&
  try_install install_dmg_app "Wireshark" "https://1.na.dl.wireshark.org/osx/Wireshark%20Latest%20Arm%2064.dmg"
want "Viscosity" "VPN" && try_install install_dmg_app "Viscosity" "https://www.sparklabs.com/downloads/Viscosity.dmg"
off mas_app 1451685025 "WireGuard" "VPN"
off page "WiFiman" "UniFi Teleport VPN" "https://ui.com/download/app/wifiman-desktop" "WiFiman Desktop"
mas_app 1168254295 "AmorphousDiskMark" "disk benchmark"
want "WhatCable" "USB-C cable checker" &&
  try_install install_zip_app "WhatCable" "$(gh_asset_url 'darrylmorley/whatcable' '^WhatCable\.zip$')"

echo "==> Browsers and chat"
want "Google Chrome" "browser" &&
  try_install install_dmg_app "Google Chrome" "https://dl.google.com/chrome/mac/universal/stable/GGRO/googlechrome.dmg"
mas_app 747648890 "Telegram" "chat"
mas_app 310633997 "WhatsApp" "chat"
want "Discord" "chat" && try_install install_dmg_app "Discord" \
  "https://discord.com/api/downloads/distributions/app/installers/latest?platform=osx&arch=arm64"
want "Zoom" "video calls" "zoom.us" &&
  try_install install_pkg_app "zoom.us" "https://zoom.us/client/latest/Zoom.pkg?archType=arm64"
page "Wispr Flow" "dictation" "https://wisprflow.ai"

echo "==> Hardware"
page "Logi Options+" "Logitech mouse buttons and scrolling; sign in to restore its settings backup" \
  "https://www.logitech.com/en-us/software/logi-options-plus.html" "logioptionsplus"
page "Calibrite PROFILER" "monitor calibration" "https://calibrite.com/us/software-downloads/" "calibrite PROFILER"
page "Display Pilot 2" "BenQ monitor settings" "https://www.benq.com/en-us/monitor/software/display-pilot-2.html"
off page "DisplayQuickit" "BenQ monitor firmware updates" \
  "https://www.benq.com/en-us/monitor/software/display-quickit.html"

report_off
report_failed
