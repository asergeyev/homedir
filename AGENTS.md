# AGENTS.md

A personal Mac setup. README.md is the user guide and each script's header says what it does; keep both current when a script's name, order, flags or behaviour changes.

**The repo is public:** no secrets, internal hosts or personal data. Work-only settings stay in the comments-only templates `conf/git/config-work` and `conf/zsh/.zprofile-work`.

## Map

- `install/` — setup steps, run in number order; 90 is the Lima fallback.
- `bin/` — tools 03 links into `~/.local/bin`; `homedir-*` back up, restore, sync configs and prune.
- `bin/agentic/` — Claude Code Bash hooks, linked into `~/.claude/hooks` and wired by path in `~/.claude/settings.json`. Warn-only and run on every Bash call, so keep them fast.
- `conf/` — tool configs; `configs.txt` lists what 03 copies into `~`, `backup-manifest.txt` what backup and restore copy, `review-configs.md` is the prompt that has Claude Code compare them all with `~`.
- `lib/` — helpers for the install scripts.
- `test/make-fixture.sh` — builds a backup of dummy data to test backup and restore on.

## Constraints

- The restore and 01–03 run on a fresh Mac, maybe offline, before the Command Line Tools. They may use only what macOS ships: `/bin/bash` 3.2, openrsync, `/usr/bin/jq`, `defaults`, `plutil`, `dscl`, `osascript`, the BSD userland. `git`, `python3`, `swift` and `make` are only stubs there, so anything needing them gets a fallback.
- Bash 3.2 everywhere: no `mapfile`, associative arrays or `${v,,}`; `${a[@]+"${a[@]}"}` for a possibly empty array under `set -u`. BSD tools: no `grep -P`, `date -d`, `stat -c` or bare `sed -i`.
- Scripts are re-runnable and move a file in the way to `<file>.bak.<time>`. Markdown not hard-wrapped; shell snippets start with a `#` comment.
- Renaming a script: `rg` the old name across the repo. A renamed hook also needs its command updated in `settings.json`.

## Testing

- Never execute 01, 02, 04–10, 90 or `homedir-prune`: whatever `$HOME` is, they change the real preferences, apps, OrbStack and caches.
- Backup and restore: `test/make-fixture.sh [DIR]` builds a fake old home, its backup and a new home, and prints the restore command. Run both only with `HOME` set to a fixture home, never on the real `~` or `~/BACKUP_FOLDER`. Under a HOME other than the login one, plists are plain files, so `defaults` never touches the real preferences.
- 03 and `homedir-sync` also run only with a scratch `HOME` when testing them; the config review (`conf/review-configs.md`) runs `homedir-sync` on the real `~` by design.
- Drive prompts with `expect`: set `env(TERM)`, escape brackets (`\[q\]uit`), `sleep 0.3` before each `send`, end answers with `\r`.
