#!/usr/bin/env bash
# PreToolUse/Bash: warn (never block) when a command chains `git add` into
# `git commit`, or uses `-a`/`-A`. Prefer the single-call pathspec form:
# git commit -m "..." -- path/one path/two. See git-branch-commit-push in the
# memory vault.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // ""')"

has_add=0
printf '%s' "$cmd" | grep -Eq '(^|[[:space:]|;&(])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+add([[:space:]]|$)' && has_add=1

has_commit=0
printf '%s' "$cmd" | grep -Eq '(^|[[:space:]|;&(])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' && has_commit=1

sweep_flag=0
printf '%s' "$cmd" | grep -Eq '(^|[[:space:]|;&(])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit[[:space:]].*(-a[[:space:]]|-am[[:space:]]|--all([[:space:]]|$))' && sweep_flag=1

reason=""
if [ "$has_add" -eq 1 ] && [ "$has_commit" -eq 1 ]; then
  reason="chains 'git add' into 'git commit'"
elif [ "$sweep_flag" -eq 1 ]; then
  reason="uses -a/--all on git commit"
fi

[ -n "$reason" ] || exit 0

jq -n --arg ctx "Warning (warn only — this command is running, nothing was blocked): the command $reason. Prefer the single-call pathspec form instead: git commit -m \"...\" -- path/one path/two — it commits only the named files and leaves the rest of the worktree untouched, unlike -a/-A or a broad add. See git-branch-commit-push in the memory vault." '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
exit 0
