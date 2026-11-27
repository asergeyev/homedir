#!/usr/bin/env bash
# PreToolUse/Bash: warn (never block) on the 3rd+ `git status` call in a
# session. Budget is ~2 per task: once at start, once pre-commit. The rule
# lives only here; the memory vault has no note for it.
set -uo pipefail

payload="$(cat)"
cmd="$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')"
session_id="$(printf '%s' "$payload" | jq -r '.session_id // "unknown"')"

printf '%s' "$cmd" | grep -Eq '(^|[[:space:]|;&(])git[[:space:]]+status([[:space:]]|$)' || exit 0

state_dir="$HOME/.claude/hooks/state"
mkdir -p "$state_dir"
counter_file="$state_dir/git-status-count-$session_id"

count=0
[ -f "$counter_file" ] && count="$(cat "$counter_file" 2>/dev/null || echo 0)"
count=$((count + 1))
printf '%s' "$count" > "$counter_file"

[ "$count" -ge 3 ] || exit 0

jq -n --arg ctx "Warning (warn only — this command is running, nothing was blocked): this is git status call #$count in the session. Budget is ~2 per task: once at task start (dirty tree? right branch?) and once before the commit ask. Skip it between your own edits, whose results already show what changed, and trust prior command output (reset --hard, commit and merge print the resulting state). For several worktrees, one wt call covers them all; don't re-check its output with git status." '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
exit 0
