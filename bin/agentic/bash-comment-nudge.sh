#!/usr/bin/env bash
# PreToolUse/Bash: warn (never block) when a command's first line is not a
# "# ..." comment describing what it does.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // ""')"

# First non-blank line.
first="$(sed -e '/^[[:space:]]*$/d' <<<"$cmd" | head -n 1)"

# Already commented - nothing to say.
if [[ "$first" =~ ^[[:space:]]*# ]]; then
  exit 0
fi

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"Reminder: shell snippets should open with a one-line '# ...' comment saying what the command does (see the shell-snippet-comment memory). The Bash tool's description field is not a substitute. Running anyway - add the comment on the next one."}}
EOF
exit 0
