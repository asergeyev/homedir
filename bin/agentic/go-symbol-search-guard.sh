#!/usr/bin/env bash
# PreToolUse(Bash) — warn-only tool-choice nudge for Go-scoped text searches.
# Never blocks: exits 0 without a permissionDecision, so the normal permission
# flow still decides the call, and the guidance reaches the model as context.
# Downgraded from deny to warn 2026-08-05 (see use-gopls-lsp in the memory vault).
# 2026-10-12: judged per simple command, not over the whole string. A search that only
# filters piped output (`make test | rg FAIL`) is skipped, and the Go scope must be on
# the search itself, not on some other part of the command. It used to fire on ~45% of
# Bash calls.
set -uo pipefail

payload=$(cat)
cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')

search_re='(^|[[:space:](])(rg|grep)([[:space:]]|$)'
printf '%s' "$cmd" | grep -Eq "$search_re" || exit 0

# One simple command per line, "P " when fed by a pipe, else "S ". Separators and comments
# inside quotes are left alone; newlines inside quotes become spaces.
segments=$(printf '%s' "$cmd" | awk '
  BEGIN { RS = "\001"; kind = "S"; seg = ""; q = "" }
  function flush(next_kind) {
    if (seg ~ /[^[:space:]]/) print kind " " seg
    seg = ""; kind = next_kind
  }
  {
    n = length($0)
    for (i = 1; i <= n; i++) {
      c = substr($0, i, 1); d = substr($0, i + 1, 1)
      if (q == "'\''") { if (c == "'\''") q = ""; seg = seg (c == "\n" ? " " : c); continue }
      if (q == "\"") {
        if (c == "\\") { seg = seg c d; i++; continue }
        if (c == "\"") q = ""
        seg = seg (c == "\n" ? " " : c); continue
      }
      if (c == "\\") { seg = seg c d; i++; continue }
      if (c == "'\''" || c == "\"") { q = c; seg = seg c; continue }
      if (c == "#" && (seg !~ /[^[:space:]]/ || substr(seg, length(seg), 1) ~ /[[:space:]]/)) {
        while (i <= n && substr($0, i, 1) != "\n") i++
        flush("S"); continue
      }
      if (c == "|" && d == "|") { flush("S"); i++; continue }
      if (c == "&" && d == "&") { flush("S"); i++; continue }
      if (c == "|") { flush("P"); continue }
      if (c == ";" || c == "\n") { flush("S"); continue }
      seg = seg c
    }
    flush("S")
  }')

go_re='\.go([^A-Za-z0-9_]|$)|--go([^A-Za-z0-9_-]|$)|(-t|--type)[ =]?go([^A-Za-z0-9_]|$)|(func|type)[[:space:]]+[A-Za-z_]'
go_scoped=0
prev=""
while IFS= read -r line; do
  kind=${line%% *}
  seg=${line#* }
  read -r first _ <<<"$seg"
  scope=$seg
  if [ "$kind" = P ]; then
    case "$first" in
      rg | grep) prev=$seg; continue ;; # filters piped output, searches no files
      xargs) scope="$prev $seg" ;;          # file list comes from the previous command
    esac
  fi
  if printf '%s' "$seg" | grep -Eq "$search_re" && printf '%s' "$scope" | grep -Eq "$go_re"; then
    go_scoped=1
    break
  fi
  prev=$seg
done <<<"$segments"
[ "$go_scoped" -eq 1 ] || exit 0

nudge=$(cat <<'EOF'
Tool-choice reminder (warn only — this command is running, nothing was blocked).

gopls MCP and rg are both permitted for Go. gopls is the better call when you are
resolving an identifier and completeness matters: go_symbol_references before changing
any definition, go_search to locate a type/func by approximate name, go_package_api for
an API surface. It excludes same-named symbols on other types, which text search cannot.

rg is the right call for non-identifier text (comments, string literals, struct/build
tags, log messages), when you do not know the identifier yet, when the build is broken
(gopls reference sets go quietly incomplete), or for files outside the active build
(other build tags, testdata, generated, vendored).

If this search was an identifier lookup, switch to gopls. See use-gopls-lsp in the
memory vault.
EOF
)

jq -n --arg ctx "$nudge" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    additionalContext: $ctx
  }
}'
exit 0
