#!/usr/bin/env bash
# 01-macos-defaults.sh — macOS preferences: key repeat speed and delay, mouse pointer speed and size, ⌘' for Writing
# Tools (all as on the old Mac), all file extensions shown, no .DS_Store files on network shares, screenshots in
# ~/Pictures/Screenshots, ~/projects in the Finder sidebar. Safe to re-run.
set -euo pipefail

echo "==> Keyboard: fast key repeat, ⌘' for Show Writing Tools (apply after logging out and back in)..."
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain NSUserKeyEquivalents -dict-add "Show Writing Tools" "@'"

echo "==> Mouse: pointer speed and size..."
defaults write NSGlobalDomain com.apple.mouse.scaling -float 1
# macOS can refuse writes to the Accessibility domain from a terminal without Full Disk Access
defaults write com.apple.universalaccess mouseDriverCursorSize -float 1.29 2>/dev/null ||
  echo "    could not set the pointer size: System Settings > Accessibility > Display > Pointer size"

echo "==> Finder: show all file extensions, no .DS_Store files on network shares..."
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

echo "==> Screenshots go to ~/Pictures/Screenshots..."
mkdir -p "$HOME/Pictures/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Pictures/Screenshots"

echo "==> Finder sidebar: ~/projects in Favorites..."
mkdir -p "$HOME/projects"
# LSSharedFileList is deprecated, but sfltool lost its add command and the list's file is privacy-protected, so this
# is what still works (checked on macOS 27.2); swift comes with the Command Line Tools.
swift -suppress-warnings - "$HOME/projects" <<'EOF' || echo "    could not add it: drag ~/projects into the sidebar"
import CoreServices
import Foundation

let target = URL(fileURLWithPath: CommandLine.arguments[1]).resolvingSymlinksInPath().path
guard let list = LSSharedFileListCreate(nil, kLSSharedFileListFavoriteItems.takeUnretainedValue(), nil)?
  .takeRetainedValue()
else { exit(1) }
var seed: UInt32 = 0
let items = (LSSharedFileListCopySnapshot(list, &seed)?.takeRetainedValue() as? [LSSharedFileListItem]) ?? []
for item in items {
  if let url = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL?,
    url.resolvingSymlinksInPath().path == target
  {
    print("    already there: \(target)")
    exit(0)
  }
}
// Insert after the current last item: passing the kLSSharedFileListItemLast placeholder segfaults swift
guard let last = items.last,
  LSSharedFileListInsertItemURL(list, last, nil, nil, URL(fileURLWithPath: target) as CFURL, nil, nil) != nil
else { exit(1) }
print("    added \(target)")
EOF

# Restart what reads these settings now; the keyboard ones wait for a logout
killall Finder SystemUIServer Dock 2>/dev/null || true
echo "Done. Log out and back in for the keyboard changes (once, after the restore, also applies what it imports)."
