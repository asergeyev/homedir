#!/usr/bin/env bash
# make-fixture.sh — Build a test backup that holds nothing real: a fake old home with a dummy file for every item
# conf/backup-manifest.txt lists (plists, MCP servers and the paths the manifest skips included), backed up by
# bin/homedir-backup, and a new home holding only a fresh homedir clone, for trying bin/homedir-restore on.
# Not built yet, so add them by hand to test them: a non-ASCII name and a symlink inside a backed-up directory, and
# symlinks in the new home whose names hold [ * ? or \ (the restore's rsync -8 and exclude_literal).
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [DIR]
Builds in DIR (default: a new temporary directory; an existing DIR must be empty):
  DIR/old     the old Mac's home: a dummy file for every manifest item, skipped.txt where the manifest skips a path
  DIR/backup  homedir-backup's copy of DIR/old
  DIR/new     the new Mac's home: only ~/projects/homedir, a repo the restore must leave alone
EOF
}

case "${1:-}" in -h|--help) usage; exit 0 ;; esac
[ $# -le 1 ] || { usage >&2; exit 2; }
SRC="$(cd "$(dirname "$0")/.." && pwd)"
DIR=${1:-$(mktemp -d)}
mkdir -p "$DIR"
[ -z "$(ls -A "$DIR")" ] || { echo "Not empty: $DIR" >&2; exit 1; }
DIR=$(cd "$DIR" && pwd -P)
OLD="$DIR/old" NEW="$DIR/new"
PLIST='<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>fixture</key><string>%s</string></dict></plist>
'

# put REL TEXT [NAME]: write TEXT to $OLD/REL, or to $OLD/REL/NAME (default fixture.txt) for a directory (trailing /)
put() {
  local f="$OLD/$1"
  case "$1" in */) f="$f${3:-fixture.txt}" ;; esac
  mkdir -p "$(dirname "$f")"
  echo "$2" >"$f"
}

# fixture_repo DIR FILE: a git repo with one commit holding FILE, the real git config left out
fixture_repo() {
  mkdir -p "$1"
  echo fixture >"$1/$2"
  (
    cd "$1" && export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
    git init -q && git -c core.excludesFile=/dev/null add . &&
      git -c user.name=fixture -c user.email=fixture@example.invalid commit -qm fixture
  )
}

echo "==> Old home: $OLD"
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in '#'*) continue ;; esac
  read -r kind path <<<"$line"
  [ -n "$kind" ] || continue
  case "$kind:$path" in
    *:mcp:*) ;;
    # Skipped paths exist too, so a test can check they stay out of the backup
    -:*) put "${path//\*/fixture}" skipped skipped.txt ;;
    '*':*) put "projects/demo/$path" skipped skipped.txt ;;
    *:Library/Preferences/*.plist) mkdir -p "$OLD/$(dirname "$path")"; printf "$PLIST" "$path" >"$OLD/$path" ;;
    *) put "$path" "$kind $path" ;;
  esac
done <"$SRC/conf/backup-manifest.txt"
# One MCP server for each mcp:<glob> line: mcp-clickhouse* (work) and * (claude)
echo '{"mcpServers": {"mcp-clickhouse-fixture": {"command": "true"}, "other-fixture": {"command": "true"}}}' \
  >"$OLD/.claude.json"
fixture_repo "$OLD/projects/demo" demo.txt
echo uncommitted >>"$OLD/projects/demo/demo.txt"
fixture_repo "$OLD/projects/homedir" old.txt

echo "==> Backup: $DIR/backup"
mkdir -p "$DIR/backup"
HOME="$OLD" "$SRC/bin/homedir-backup" --to "$DIR/backup"

echo "==> New home: $NEW"
fixture_repo "$NEW/projects/homedir" new.txt

cat <<EOF

Fixture ready. Try the restore as the new Mac:
  HOME=$NEW $SRC/bin/homedir-restore --from $DIR/backup [--only LIST | --all] [--guided] [--dry-run]
EOF
