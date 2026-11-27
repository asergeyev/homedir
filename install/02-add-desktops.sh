#!/usr/bin/env bash
# 02-add-desktops.sh — Add desktops (Spaces) until the main display has N (default 4), for the ⌘1–⌘4 shortcuts the
# restore brings back. macOS has no setting or command for this, so it clicks "+" in Mission Control, and the
# terminal running it needs Accessibility access (macOS asks the first time). Safe to re-run.
set -euo pipefail

want=${1:-4}
case "$want" in '' | *[!0-9]*) echo "usage: $0 [desktops on the main display, default 4]" >&2; exit 2 ;; esac

# Desktops (type 0; full-screen apps are type 4) on the main display, as the Dock last saved them
have=$(defaults export com.apple.spaces - | plutil -convert json -o - - | jq '[.SpacesDisplayConfiguration
  ["Management Data"].Monitors[] | select(."Display Identifier" == "Main") | .Spaces[]? | select(.type == 0)] | length') ||
  { echo "Could not count desktops in com.apple.spaces: add them by hand in Mission Control." >&2; exit 1; }
if [ "$have" -ge "$want" ]; then
  echo "==> The main display already has $have desktops"
  exit 0
fi

echo "==> Adding $((want - have)) desktop(s) in Mission Control..."
osascript - "$((want - have))" <<'EOF' || { echo "    could not add them: add desktops by hand in Mission Control" >&2; exit 1; }
on run argv
	-- Reading the Dock's UI needs Accessibility access: check it before Mission Control opens
	try
		tell application "System Events" to count UI elements of process "Dock"
	on error
		error "give your terminal Accessibility access (System Settings > Privacy & Security > Accessibility) and run again"
	end try
	do shell script "open -a 'Mission Control'"
	delay 1
	try
		tell application "System Events" to tell process "Dock"
			repeat ((item 1 of argv) as integer) times
				click button 1 of group "Spaces Bar" of group 1 of group "Mission Control"
				delay 0.5
			end repeat
		end tell
	on error e
		tell application "System Events" to key code 53
		error "no + button where Mission Control used to have it (" & e & ")"
	end try
	tell application "System Events" to key code 53
end run
EOF
echo "    done"
