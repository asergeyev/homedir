#!/usr/bin/env bash
# PreToolUse/Bash: warn (never block) when `git commit` is about to run while
# the current branch is main/master. Branch first — see git-branch-commit-push
# in the memory vault.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // ""')"

# Only look at commands that actually invoke `git commit`.
printf '%s' "$cmd" | grep -Eq '(^|[[:space:]|;&(])git([[:space:]]+-[^[:space:]]+)*[[:space:]]+commit([[:space:]]|$)' || exit 0

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null)"
case "$branch" in
  main|master)
    ;;
  *)
    exit 0
    ;;
esac

jq -n --arg ctx "Warning (warn only — this commit is running, nothing was blocked): current branch is '$branch'. The standing rule is never commit directly to main — branch first (git switch -c <feature-branch>), then commit there. See git-branch-commit-push in the memory vault." '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
exit 0
