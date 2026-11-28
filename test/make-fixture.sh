#!/usr/bin/env bash
# make-fixture.sh — Build a test backup that holds nothing real: a fake old home with a dummy file for every item
# conf/backup-manifest.txt lists (plists, MCP servers and the paths the manifest skips included), backed up by
# bin/homedir-backup, and a new home holding a fresh homedir clone, for trying bin/homedir-restore on.
# The extras test/check.sh needs: a non-ASCII name, a symlink, a FIFO and a socket in a backed-up directory (rsync -8;
# specials skipped), files in the old home whose names hold [ * ? or \, which the new home has as symlinks to keep
# (exclude_literal), and a linked worktree of demo on a detached HEAD with a commit no branch has.
set -euo pipefail

usage() {
  cat <<EOF
Usage: $(basename "$0") [DIR]
Builds in DIR (default: a new temporary directory; an existing DIR must be empty):
  DIR/old     the old Mac's home: a dummy file for every manifest item, skipped.txt where the manifest skips a path
  DIR/backup  homedir-backup's copy of DIR/old
  DIR/new     the new Mac's home: only ~/projects/homedir, a repo the restore must leave alone, and the symlinks
  DIR/demo-origin.git  the remote of ~/projects/demo, a commit behind it
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

# put REL TEXT [NAME]: write TEXT to $OLD/REL, or to $OLD/REL/NAME (default fixture.txt) for a directory (trailing /)
put() {
  local f="$OLD/$1"
  case "$1" in */) f="$f${3:-fixture.txt}" ;; esac
  mkdir -p "$(dirname "$f")"
  echo "$2" >"$f"
}

# put_plist REL: a plist at $OLD/REL holding its own path
put_plist() {
  mkdir -p "$OLD/$(dirname "$1")"
  printf '%s\n' '<?xml version="1.0" encoding="UTF-8"?>' \
    "<plist version=\"1.0\"><dict><key>fixture</key><string>$1</string></dict></plist>" >"$OLD/$1"
}

# Names the restore's rsync patterns would take as wildcards
GLOB_NAMES=('foo[1]' 'bar*baz' 'x\y[1]' 'q?x' plain-link)

# fgit ARG...: git with the real git config left out, committing as fixture
fgit() {
  GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 \
    git -c user.name=fixture -c user.email=fixture@example.invalid -c core.excludesFile=/dev/null "$@"
}

# fixture_repo DIR FILE: a git repo with one commit holding FILE
fixture_repo() {
  mkdir -p "$1"
  echo fixture >"$1/$2"
  fgit -C "$1" init -q && fgit -C "$1" add . && fgit -C "$1" commit -qm fixture
}

echo "==> Old home: $OLD"
ITEMS='|'
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in '#'*) continue ;; esac
  read -r kind path <<<"$line"
  [ -n "$kind" ] || continue
  case "$kind:$path" in
    *:mcp:*) ;;
    # A skip that is also an item (Documents/Obsidian/ inside Documents/) is backed up as that item
    -:*) case "$ITEMS" in *"|$path|"*) ;; *) put "${path//\*/fixture}" skipped skipped.txt ;; esac ;;
    '*':*) put "projects/demo/$path" skipped skipped.txt ;;
    *:Library/Preferences/*.plist) put_plist "$path" ;;
    # Valid JSON, as the restore reads Claude Code's settings
    *.json) put "$path" "{\"fixture\": \"$kind $path\"}" ;;
    *) put "$path" "$kind $path" ;;
  esac
  case "$kind" in -|'*') ;; *) ITEMS="$ITEMS$path|" ;; esac
done <"$SRC/conf/backup-manifest.txt"
# One MCP server for each mcp:<glob> line: mcp-clickhouse* (work) and * (claude)
echo '{"mcpServers": {"mcp-clickhouse-fixture": {"command": "true"}, "other-fixture": {"command": "true"}}}' \
  >"$OLD/.claude.json"
fixture_repo "$OLD/projects/demo" demo.txt
# demo's origin lacks its last commit, which the git report must list
fgit init -q --bare "$DIR/demo-origin.git"
fgit -C "$OLD/projects/demo" remote add origin "$DIR/demo-origin.git"
fgit -C "$OLD/projects/demo" push -q origin HEAD
fgit -C "$OLD/projects/demo" commit -q --allow-empty -m 'not pushed'
fgit -C "$OLD/projects/demo" worktree add -q --detach "$OLD/projects/demo-wt"
fgit -C "$OLD/projects/demo-wt" commit -q --allow-empty -m detached
echo uncommitted >>"$OLD/projects/demo/demo.txt"
fixture_repo "$OLD/projects/homedir" old.txt
put .config/mc/ fixture 'note — café 🚀.md'
ln -s fixture.txt "$OLD/.config/mc/link"
mkfifo "$OLD/.config/mc/fixture.fifo"
# Bound by a relative name: a socket's path may be only 104 bytes
(cd "$OLD/.config/mc" &&
  perl -MIO::Socket::UNIX -e 'IO::Socket::UNIX->new(Local => "fixture.sock", Listen => 1) or die "socket: $!\n"')
for n in "${GLOB_NAMES[@]}"; do put .config/zed/ backup "$n"; done

echo "==> Backup: $DIR/backup"
mkdir -p "$DIR/backup"
HOME="$OLD" "$SRC/bin/homedir-backup" --to "$DIR/backup"

echo "==> New home: $NEW"
fixture_repo "$NEW/projects/homedir" new.txt
mkdir -p "$NEW/.config/zed"
for n in "${GLOB_NAMES[@]}"; do ln -s /nowhere "$NEW/.config/zed/$n"; done

cat <<EOF

Fixture ready. Try the restore as the new Mac:
  HOME=$NEW $SRC/bin/homedir-restore --from $DIR/backup [--only LIST | --all] [--guided] [--dry-run]
EOF
