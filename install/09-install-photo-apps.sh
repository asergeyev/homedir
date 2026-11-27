#!/usr/bin/env bash
# 09-install-photo-apps.sh [--all] — For the photo machine: ask about each photo app and open its
# download page. Lightroom Classic and Photoshop install through Adobe Creative Cloud. Apps already installed are
# skipped without asking; lines marked `off` are asked about only with --all. Safe to re-run.
set -euo pipefail
. "$(dirname "$0")/../lib/funcs.sh"
parse_flags "$@"
need_terminal

page "Lightroom Classic" "photo library and editing" "https://creativecloud.adobe.com/apps/download/lightroom-classic" \
  "Adobe Lightroom Classic/Adobe Lightroom Classic"
# Photoshop's folder and app carry the release year (Adobe Photoshop 2026)
page "Photoshop" "image editing" "https://creativecloud.adobe.com/apps/download/photoshop" \
  "Adobe Photoshop */Adobe Photoshop *"

report_off
report_failed
