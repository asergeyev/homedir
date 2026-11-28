#!/usr/bin/env bash
# check.sh — Lint every shell script with shellcheck, then test backup and restore on a fixture (make-fixture.sh):
# the backup skips what it must and lists unpushed commits, a plan right after it finds everything the same and spots
# a changed copy, and the restore copes with odd names, symlinks and its guided prompts, then leaves nothing to
# restore. Prints PASS or FAIL per check and exits 1 if any failed, keeping the fixture to look at. Needs shellcheck
# (homedir's mise config lists it) and expect (macOS ships it). Never touches the real ~.
# shellcheck disable=SC2319 # ok $? reads the test on the line before, as meant
set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"
cd "$SRC" || exit 1
FAILS=0

# ok RC NAME: report NAME as PASS when RC is 0
ok() {
  if [ "$1" = 0 ]; then echo "PASS $2"; else echo "FAIL $2"; FAILS=$((FAILS + 1)); fi
}

echo "==> shellcheck"
# Every shell script in the checkout, new ones included, by extension or by its #! line; .shellcheckrc holds the
# settings
scripts=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  case "$f" in
    *.sh) scripts+=("$f") ;;
    *) if head -n 1 "$f" | grep -qE '^#!.*[/ ](ba)?sh( |$)'; then scripts+=("$f"); fi ;;
  esac
done < <(git ls-files --cached --others --exclude-standard)
if command -v shellcheck >/dev/null 2>&1; then
  shellcheck "${scripts[@]}"
  ok $? "shellcheck: ${#scripts[@]} scripts"
else
  ok 1 "shellcheck: not installed (mise install shellcheck)"
fi

echo "==> Fixture and its backup"
TMP=$(mktemp -d)
FX=$TMP/fx OLD=$TMP/fx/old NEW=$TMP/fx/new B=$TMP/fx/backup
test/make-fixture.sh "$FX" >"$TMP/fixture.log" 2>&1
ok $? "make-fixture.sh and homedir-backup"
if [ ! -f "$B/backup-manifest.txt" ]; then
  echo "No backup to test the rest on"
  exit 1
fi
[ -z "$(find "$B/home" -name skipped.txt)" ]
ok $? "the manifest's skipped paths stay out"
[ -p "$OLD/.config/mc/fixture.fifo" ] && [ -S "$OLD/.config/mc/fixture.sock" ] &&
  [ ! -e "$B/home/.config/mc/fixture.fifo" ] && [ ! -e "$B/home/.config/mc/fixture.sock" ]
ok $? "a FIFO and a socket are skipped"
[ -f "$B/home/.config/mc/note — café 🚀.md" ] && [ -L "$B/home/.config/mc/link" ]
ok $? "a non-ASCII name and a symlink are copied"
awk '/^=== demo ===$/, /^$/' "$B/git-report/summary.txt" | grep -qE '^[0-9a-f]+ \(HEAD -> [^)]+\) not pushed$'
ok $? "the git report lists a commit its remote lacks"
awk '/^=== homedir ===$/, /^$/' "$B/git-report/summary.txt" | grep -q '^(no remote'
ok $? "the git report flags a repo with no remote"
awk '/^=== demo-wt ===$/, /^$/' "$B/git-report/summary.txt" | grep -qE '^[0-9a-f]+ \(HEAD\) detached$'
ok $? "the git report lists a commit on a worktree's detached HEAD"
[ -s "$B/git-report/demo.unstaged.diff" ]
ok $? "the git report saves an uncommitted change"

# not_same OUTPUT: the plan's item lines that aren't "same"
not_same() {
  printf '%s\n' "$1" | awk '/^==>/ { on = 1; next } /^$/ { on = 0 } on && $NF != "same"'
}

echo "==> The plan on the old home, right after the backup"
out=$(HOME=$OLD bin/homedir-restore --from "$B" 2>&1)
ok $? "plan runs"
bad=$(not_same "$out")
[ -z "$bad" ]
ok $? "every item is the same"
[ -z "$bad" ] || printf '%s\n' "$bad" | sed 's/^/      /'
# Outside the bulk groups it compares contents: a changed byte, same size and time, shows
for f in .zshrc .config/zed/fixture.txt; do
  cp -p "$B/home/$f" "$TMP/${f##*/}.orig"
  printf X | dd of="$B/home/$f" bs=1 conv=notrunc 2>/dev/null
  touch -r "$TMP/${f##*/}.orig" "$B/home/$f"
done
out=$(HOME=$OLD bin/homedir-restore --from "$B" 2>&1)
printf '%s\n' "$out" | grep -qE '^ +~/\.zshrc +differs$' &&
  printf '%s\n' "$out" | grep -qE '^ +~/\.config/zed/ +1 changed file$'
ok $? "it spots a changed copy of a file and of a file in a directory"
cp -p "$TMP/.zshrc.orig" "$B/home/.zshrc"
cp -p "$TMP/fixture.txt.orig" "$B/home/.config/zed/fixture.txt"

echo "==> Guided restore into the new home"
# guided.exp prints "### exit RC" at the end
expect -f test/guided.exp bin/homedir-restore "$NEW" "$B" true '~/.config/wireshark/' list >"$TMP/list.log" 2>&1
grep -q '### exit 0' "$TMP/list.log"
ok $? "[l]ist with a pager that quits at once"
expect -f test/guided.exp bin/homedir-restore "$NEW" "$B" cat '~/.config/mc/' file >"$TMP/file.log" 2>&1
grep -q '### exit 0' "$TMP/file.log" && [ -f "$NEW/.config/mc/note — café 🚀.md" ]
ok $? "[f]ile by file restores a non-ASCII name"
[ -L "$NEW/.config/mc/link" ] && [ "$(readlink "$NEW/.config/mc/link")" = fixture.txt ]
ok $? "[f]ile by file restores a symlink as one"

echo "==> Restore into the new home"
HOME=$NEW bin/homedir-restore --from "$B" --only '~/.config/zed/' >"$TMP/zed.log" 2>&1
ok $? "--only a directory"
kept=0
for n in 'foo[1]' 'bar*baz' 'x\y[1]' 'q?x' plain-link; do
  [ -L "$NEW/.config/zed/$n" ] || kept=1
done
ok $kept "symlinks here whose names hold [ * ? or \\ stay"
HOME=$NEW bin/homedir-restore --from "$B" --only projects >"$TMP/projects.log" 2>&1
ok $? "--only projects"
mkdir -p "$NEW/.local/state/homedir"
echo projects/homedir >"$NEW/.local/state/homedir/protected-repos"
expect -f test/guided.exp bin/homedir-restore "$NEW" "$B" true projects none >"$TMP/stale.log" 2>&1
[ ! -e "$NEW/.local/state/homedir/protected-repos" ]
ok $? "a guided run clears a stale protected-repos list"
HOME=$NEW bin/homedir-restore --from "$B" --all >"$TMP/all.log" 2>&1
ok $? "--all"
! grep -qiE 'error|failed' "$TMP/all.log"
ok $? "--all prints no error"
[ -f "$NEW/projects/homedir/new.txt" ] && [ ! -e "$NEW/projects/homedir/old.txt" ]
ok $? "the homedir clone here is left alone"
[ "$(git -C "$NEW/projects/demo" log -1 --format=%s 2>/dev/null)" = "not pushed" ]
ok $? "a repo comes back with its unpushed commit"
[ "$(stat -f %Lp "$NEW/.ssh/fixture.txt")" = 600 ] && [ "$(stat -f %Lp "$NEW/.ssh")" = 700 ]
ok $? "secrets come back owner-only"
[ "$(jq -c '.mcpServers | keys' "$NEW/.claude.json" 2>/dev/null)" = '["mcp-clickhouse-fixture","other-fixture"]' ]
ok $? "MCP servers are merged into ~/.claude.json"
out=$(HOME=$NEW bin/homedir-restore --from "$B" 2>&1)
bad=$(not_same "$out")
[ -z "$bad" ]
ok $? "a plan afterwards finds every item the same"
[ -z "$bad" ] || printf '%s\n' "$bad" | sed 's/^/      /'

if [ "$FAILS" = 0 ]; then
  rm -rf "$TMP"
  echo "All passed"
else
  echo "$FAILS failed; the fixture and logs are in $TMP"
  exit 1
fi
