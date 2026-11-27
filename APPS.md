# GUI Applications (No Brew Cask Bloat)

- `./install/05-install-apps.sh` — the apps every reinstall gets, straight from the vendors (`.zip`/`.dmg`), no questions.
- `./install/06-install-optional-apps.sh` — asks about each optional app: vendor downloads, Mac App Store apps (installs `mas` from GitHub Releases the first time; sign into the App Store app first), and opens the download page for apps with no direct link.
- `./install/07-install-safari-extensions.sh` — asks about each Safari extension (Mac App Store).
- `./install/09-install-photo-apps.sh` — the photo machine only: asks about each photo app.
- Apps marked *off* are skipped; run the script with `--all` to be asked about them too.
- By hand: 1Password (README step 2, before homedir is cloned) and OrbStack (download portal only).

## Always installed
- **1Password** (by hand; turn on its SSH Agent, which GitHub SSH goes through, and add the browser extension)
- **iTerm2** (profiles and settings come back with `bin/homedir-restore`)
- **Obsidian** (point to `~/Documents/Obsidian`)
- **Visual Studio Code** (primary editor; settings + curated extensions in `conf/vscode/`)
- **Claude.app** + **Claude Code CLI** (the CLI is installed by `04-bootstrap-host.sh`)
- **Antigravity.app** + **Antigravity CLI** (`agy`, installed by `04-bootstrap-host.sh`; current choice over Antigravity IDE)
- **Slack**, **Signal**
- By hand: **OrbStack** (`https://orbstack.dev` — Docker engine + `dev` & `clickhouse` Linux machines)

## Optional (`06-install-optional-apps.sh` asks)
- **Productivity:** Notion, Linear; off: TickTick
- **Dev & networking:** Insomnia (API client, current choice over Bruno, Postman, Scalar), xbar (menu bar Git tags plugin, linked by `03-link-configs.sh`), Zed (lightweight secondary editor), Wireshark (packet inspection), Viscosity (VPN), AmorphousDiskMark (disk benchmark), WhatCable (USB-C cable checker); off: WireGuard, WiFiman (UniFi Teleport)
- **Browsers & chat:** Google Chrome (current choice over Edge, Brave, Arc, Opera, Vivaldi, DuckDuckGo), Telegram, WhatsApp, Discord, Zoom, Wispr Flow
- **Hardware:** Logi Options+ (sign in to restore its settings backup), Calibrite PROFILER, BenQ Display Pilot 2; off: BenQ DisplayQuickit

## Safari extensions (`07-install-safari-extensions.sh` asks)
- 1Password for Safari, Obsidian Web Clipper, Ghostery (ad and tracker blocker)
- Speed Player
- Off: BetterJSON, PrettyJSON for Safari (JSON viewers)

## Photo machine (`09-install-photo-apps.sh` asks)
- Lightroom Classic, Photoshop (both through Adobe Creative Cloud)

## Taxes (by hand)
- H&R Block 2024–2026: no public Mac installer; download each year's edition from H&R Block after buying it.
