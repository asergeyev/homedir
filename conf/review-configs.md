# Config review

`homedir-sync` compares only the `sync` configs, and only reports. A `seed` config (mc's options and hotlist, the work templates, `ignore-revs`) is copied once and never compared, so a change in it worth giving the next Mac never comes back by itself. This prompt has Claude Code compare every config in [`configs.txt`](configs.txt) with yours and propose changes to `conf/`, which it makes once you pick them.

```sh
# From this checkout: review every config and propose changes to conf/
claude "Follow conf/review-configs.md"
```

## Instructions for Claude

Find how each config in `~` differs from homedir's copy in `conf/`, and propose for each difference that matters what to do about it. Change `conf/` only after the user picks which proposals to take. Never change files in `~` unless asked, and don't commit.

### Read safely

Configs in `~` can hold tokens and passwords. Never Read or cat them: see them only through the diff command below, which redacts secret-looking values; for more context, rerun it with `diff -U 20` in place of `diff -u`. If a value that got through still looks like a secret, don't repeat it anywhere. If a redacted line plainly isn't a secret (`editor.tokenColorCustomizations`) and it matters, ask the user to paste it rather than opening the file.

1. Read `AGENTS.md`, above all: the repo is public, so no secrets, internal hosts or personal data.
2. Run `bin/homedir-sync`, without `--diff`. For each `sync` config it says which side changed since the two last matched: yours, homedir's (pulled from another Mac) or both. As designed, it also records the match for a config that is the same.
3. Run the command below for the differences of every config, homedir's on the `-` side.

```sh
# Each config in configs.txt against yours, and for sync ones homedir's changes since the last sync; secrets redacted
/bin/bash <<'EOF'
cd "$(git rev-parse --show-toplevel)" || exit 1
B=$HOME/.local/state/homedir/base
while read -r mode tool rel dst; do
  case "$mode" in sync | seed) ;; *) continue ;; esac
  echo "##### $mode $tool: ~/$dst"
  if [ ! -e "$HOME/$dst" ]; then echo "(not in ~)"; continue; fi
  diff -u --label "homedir: $rel" --label "yours: ~/$dst" "$rel" "$HOME/$dst" && echo "(same)"
  if [ "$mode" = sync ] && [ -f "$B/$dst" ] && ! cmp -s "$B/$dst" "$rel"; then
    echo "### homedir's changes since the last sync"
    diff -u --label "last sync" --label "homedir: $rel" "$B/$dst" "$rel"
  fi
done <conf/configs.txt | perl -pe '
  s{((?i:(?:token|secret|passw|pwd|api_?key|access_?key|private_?key|credential|authorization|bearer)[\w"]*
    |_(?:pat|pass|auth|key)(?![a-z])"?)\s*[=:]\s*).+}{$1<redacted>}x;
  s{\b(?:gh[pousr]_|github_pat_|glpat-|sk-|xox[abprs]-|AKIA|ASIA)[\w-]{8,}}{<redacted>}g;
  s{(://)(?:[^/\s@:]*:[^/\s@]*|[^/\s@:]{16,})@}{$1<redacted>@}g'
EOF
```

### Sort each difference

Give each hunk one of these:

- **Into homedir:** a general improvement every Mac on this setup should have, like an alias, a tool setting, or a PATH entry for a tool homedir installs. Write it into `conf/` generically, with `$HOME` or `~` and no user name. In a `seed` config this makes the new seed, which only a new Mac or `--reset` gets.
- **Only in homedir's:** homedir has something yours lacks. Usually homedir gained it after your copy was made. For a `sync` config, `homedir-sync` says so ("changed in homedir"); for a `seed` one, or a `sync` one with no earlier sync, `git log -S '<text>' --oneline -- conf/<file>` shows when homedir added it. Then nothing changes in homedir: tell the user how to take it, either `cp conf/<file> ~/<path>` when theirs has nothing of its own, or copying the lines in by hand (`install/03-link-configs.sh --reset TOOL` loses their changes). Only if it was in homedir all along, so the user likely removed it, ask whether homedir should drop it too; never propose that unasked.
- **Work-only:** company hosts, private orgs, work accounts, `GOPRIVATE`. Never put these in `conf/`. If one sits in a main config, propose moving it to `~/.zprofile-work` or `~/.config/git/config-work`, which homedir's configs source and include last. Everything in the user's copies of those two work templates is work-only, so nothing in them goes into homedir. The templates in `conf/` stay comments-only; add a commented example there only when the user asks, with placeholders like `example.com`.
- **Secret:** keep it out of `conf/`. If it sits in a config at all, suggest where it belongs instead (1Password, the keychain, a `-work` file), naming only the key.
- **This Mac only:** paths, hardware, a one-off experiment. It stays in `~`.
- **Tool churn:** what the tool writes itself, like mc's window sizes, history and last directories, or VS Code's UI state and key order. Ignore it. A `sync` config that churns on every use is better off as `seed` (as mc's `ini` is), so propose that change to `configs.txt`.

Ignore whitespace-only differences, unless whitespace is all that keeps a `sync` config from matching. Then aligning homedir's file with yours lets `homedir-sync` record the match.

### Report

1. Show one table, grouped by config. It gives the difference in a few words (never a secret value), its kind, and the action you propose. Leave out configs that are the same and differences you ignore; give one line saying how many there were.
2. Number the actions that change `conf/` or `configs.txt`, and ask which to take.
3. Make the chosen changes, keeping each file's comments, order and style. Then show `git diff`, and `bin/homedir-sync` for the `sync` states.
