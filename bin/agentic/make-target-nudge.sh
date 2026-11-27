#!/usr/bin/env bash
# PreToolUse/Bash: warn (never block) when the Go toolchain is driven directly
# instead of through this repo's make targets. go mod / go env / go run are
# deliberately NOT matched - they have no make equivalent and are legitimate.
# Text that only mentions the commands doesn't count: single-quoted strings,
# double-quoted strings without a $(...) or backtick, comments and heredoc
# bodies are removed before matching, so echo/printf text, rg/grep patterns,
# commit messages and scripts fed through <<EOF stay quiet.
set -uo pipefail

cmd="$(jq -r '.tool_input.command // ""')"

code="$(awk '
  hd { t = $0; if (hstrip) sub(/^\t+/, "", t); if (t == delim) hd = 0; next }
  {
    line = $0; out = ""; hdnext = 0
    if (st == 0 && match(line, /(^|[^<])<<-?[ \t]*["\047]?[A-Za-z_][A-Za-z0-9_]*["\047]?/)) {
      d = substr(line, RSTART, RLENGTH); sub(/^[^<]/, "", d)
      hstrip = (d ~ /^<<-/); sub(/^<<-?[ \t]*/, "", d); gsub(/["\047]/, "", d)
      delim = d; hdnext = 1
    }
    n = length(line)
    for (i = 1; i <= n; i++) {
      c = substr(line, i, 1)
      if (st == 1) { if (c == "\047") st = 0; continue }
      if (st == 2) {
        if (c == "\\") { buf = buf c substr(line, i + 1, 1); i++; continue }
        if (c == "\"") { if (buf ~ /\$\(|`/) out = out " " buf " "; buf = ""; st = 0; continue }
        buf = buf c; continue
      }
      if (c == "\\") { out = out c substr(line, i + 1, 1); i++; continue }
      if (c == "\047") { st = 1; continue }
      if (c == "\"") { st = 2; buf = ""; continue }
      if (c == "#" && (i == 1 || substr(line, i - 1, 1) ~ /[ \t;&|(]/)) break
      out = out c
    }
    if (st == 2) buf = buf "\n"
    print out
    if (hdnext) hd = 1
  }
' <<<"$cmd")"

hits=()
grep -Eq '(^|[^[:alnum:]_./-])go[[:space:]]+test([^[:alnum:]_-]|$)'  <<<"$code" && hits+=("go test -> make test")
grep -Eq '(^|[^[:alnum:]_./-])go[[:space:]]+build([^[:alnum:]_-]|$)' <<<"$code" && hits+=("go build -> make build/<target>")
grep -Eq '(^|[^[:alnum:]_./-])go[[:space:]]+vet([^[:alnum:]_-]|$)'   <<<"$code" && hits+=("go vet -> make ci")
grep -Eq '(^|[^[:alnum:]_./-])gofmt([^[:alnum:]_-]|$)'               <<<"$code" && hits+=("gofmt -> gofumpt")

[[ ${#hits[@]} -eq 0 ]] && exit 0

joined="$(printf '%s; ' "${hits[@]}")"

jq -cn --arg j "${joined%; }" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: ("Tool-choice reminder (warn only - this command is running, nothing was blocked). " +
      "Use the repo'"'"'s make targets, not the Go toolchain directly: " + $j + ". " +
      "make test is the GOWORK=off / CI-parity run; make test-workspace keeps the workspace on. " +
      "Formatting is gofumpt, never gofmt. See go-work-workspace and preferred-cli-tools in the memory vault. " +
      "go mod, go env and go run are fine and are not matched by this hook.")
  }
}'
exit 0
