# homedir -- opinionated way to prepare mac for work

Workstation setup for Apple Silicon macOS with **zero Homebrew**, applied by reinstalling: wipe the Mac, then rebuild it from this repo plus a backup of the files worth keeping. No Migration Assistant, no full Time Machine restore.

- **Host macOS:**
  - Xcode Command Line Tools (`git`, `make`, `ssh`, `curl`)
  - [`mise`](https://mise.jdx.dev/) for runtimes and core CLIs: `go` (latest 1.x), `node`, `pnpm`, `uv`, `jq`, `yq`, `gh`, `glab`, `rg`, `delta`, `oasdiff`, `mc` (Midnight Commander, from conda-forge)
  - `uv`-managed Python: the newest is the default `python3`/`python` in `~/.local/bin`, with 3.12 alongside for irregular CA clients
  - Go tools in `~/go/bin` (`gopls`, `gofumpt`, `golangci-lint-v2`, `dlv`, `garble`, `protoc-gen-go`, `docker-credential-ecr-login`, plus the private ones your `~/.zprofile-work` lists)
  - OrbStack for `docker`, `docker compose`, `docker buildx` and the Linux machines below, with one 20 GB memory limit for all of them, not started at login. Docker's `credsStore` is `ecr-login`, so ECR images pull with your `AWS_PROFILE`; other registries pull anonymously.
  - Standalone `clickhouse` client
  - VS Code (Zed optional), Claude.app and Antigravity.app with their CLIs (`claude`, `agy`); the rest in [`APPS.md`](APPS.md)
- **OrbStack Linux machines** (Lima stays only as an [emergency rollback](#rolling-back-to-lima)):
  - `dev`: Ubuntu toolbox for `aws`, `ansible`, `terraform`/`tf`, `terragrunt`, `kubectl`, `k9s`, `helm`, `trivy`, `nmap`, `iperf3`. On the host each is a `~/.local/bin` link to `bin/vm-shim`, which runs it in `dev` with your AWS profile, region and `KUBECONFIG`, never secrets (`kubectl` is OrbStack's own; `dev kubectl` runs the VM's). The VM home links `~/.aws`, `~/.kube`, `~/.ssh`, `~/.s3cfg` and `~/.config/{gh,glab-cli}` to the Mac copies and trusts every CA in `~/.config/ca-certificates/`.
  - `clickhouse`: scratch instance, latest version by default; stopped until `orbctl start clickhouse`.

A minimal reinstall works without internet too: the restore needs only what macOS ships and the backup carries homedir, so restore `secrets,work,~/projects/homedir/` instead of cloning, run `01`–`03`, and continue from `04` once online.

## Configs: copied, synced back with homedir-sync

`conf/` holds the configs for zsh, git, mise, VS Code and mc. `install/03-link-configs.sh` copies each one in [`conf/configs.txt`](conf/configs.txt) into `~` where there is none yet. From then on the file is yours: the backup saves it, the restore puts it back, and nothing you or a tool change in it (`git config --global`, VS Code, mc) reaches this public repo by itself.

`homedir-sync` brings the `sync` ones together. It compares each with `conf/` and with the copy from the last sync, so it knows which side changed (yours, homedir's pulled from another Mac, or both), and asks which way to copy: yours into homedir, homedir's into `~` (yours kept as `<file>.bak.<time>`), or both merged when they merge cleanly. Then it offers to commit the changed `conf/` files on the current branch, never on `main`, and never pushes. `--status` only shows how they compare.

```sh
# Compare the configs with homedir's, copy either way, then commit
homedir-sync
```

The `seed` ones are copied once and never synced back: `ignore-revs`, mc's hotlist and the two work templates. To start a tool over from homedir's copy, `--reset` overwrites yours, so use it carefully: your changes are gone (the old file stays as `<file>.bak.<time>`):

```sh
# Overwrite your mc hotlist with homedir's
./install/03-link-configs.sh --reset mc-hotlist
```

The zsh and git configs are personal. Work settings go in `~/.zprofile-work`, sourced last by `~/.zprofile` (`GOPRIVATE`, the private Go tools `04` installs, work aliases), and `~/.config/git/config-work`, included last by the git config (a work `[user]`, SSH rewrites for private orgs). homedir ships both as commented templates (tools `zsh-work` and `git-work`, so `--reset zsh,git` leaves them alone; never synced, so your work settings stay out of this repo); the restore brings yours back in its `work` group.

Scripts in `bin/`, the dev-VM shims, the Lima templates and the xbar plugin stay symlinks into this checkout. `03` also links `bin/agentic/`, Claude Code's warn-only Bash hooks, into `~/.claude/hooks/`; a hook removed here leaves a dangling link there to delete.

## Reinstall

First save the old Mac's state ([Saving Mac state before reinstall](#saving-mac-state-before-reinstall)). Then:

### 1. Erase and set up macOS

1. **System Settings → General → Transfer or Reset → Erase All Content and Settings…**
2. On first boot:
   - Create your user with the same short name as on the old Mac, so absolute paths in restored files (`/Users/<you>/projects`, the Obsidian vault) still match.
   - Turn on **FileVault** and **Touch ID**.
   - **Skip Migration Assistant.**
3. Install the Xcode Command Line Tools:
   ```sh
   xcode-select --install
   ```

### 2. 1Password, secrets, homedir, macOS preferences, host tools

GitHub SSH goes through 1Password's SSH agent (the restored `~/.ssh/config` points `github.com` at it), so 1Password comes first: download it from https://1password.com/downloads/mac, sign in, and turn on **Settings → Developer → Use the SSH agent**. Then:

```sh
# Re-link the backup folder on the external drive (named for the day the backup was made)
ln -sfn /Volumes/<Drive>/reinstall.<YYYY-MM-DD> ~/BACKUP_FOLDER

# Secrets first, so git can clone over SSH, and the work group: work zsh and git settings, AWS, kube, CAs, glab,
# Viscosity, Insomnia, the ClickHouse MCP servers (a personal Mac: --only secrets). The backup carries this script.
bash ~/BACKUP_FOLDER/homedir-restore --only secrets,work

# Clone homedir
mkdir -p ~/projects
git clone git@github.com:asergeyev/homedir.git ~/projects/homedir
cd ~/projects/homedir

# macOS preferences: key repeat speed and delay, mouse pointer speed and size, ⌘' for Writing Tools, file extensions,
# the screenshot folder, ~/projects in the Finder sidebar
./install/01-macos-defaults.sh

# 4 desktops on the main display, for the ⌘1–⌘4 shortcuts step 4 restores: clicks "+" in Mission Control, so macOS
# asks to let your terminal control System Events (allow it) and for its Accessibility access (grant it, run again)
./install/02-add-desktops.sh

# Link scripts, Claude Code's hooks and the xbar plugin; copy the tool configs where none exist
./install/03-link-configs.sh

# Restart this shell on homedir's zsh config (the new PATH, 200k-line history) with exec, not by closing the window:
# a Terminal shell started before 03 trims the restored ~/.zsh_history to macOS's 1000 lines when it exits
exec zsh -l

# Bootstrap mise, uv Pythons, the clickhouse client, Go tools, the claude and agy CLIs and Fira Code
./install/04-bootstrap-host.sh
```

The keyboard settings apply after a logout; one at the end (step 5) covers them and the restore. Desktops have per-Mac ids, so the backup can't carry them: if 02 can't add them (Mission Control's layout moves between macOS versions), add them by hand. You can remove the terminal's Accessibility access afterwards.

**Private Go modules:** `04` sources `~/.zprofile-work` for `GOPRIVATE` and the private tools it installs, and `~/.config/git/config-work` sends those clones over SSH, so both work files and the SSH keys restored above must be in place. Check with:
```sh
# Should list refs over SSH without prompting for credentials
git ls-remote https://github.com/orgname/<repo> HEAD
```

### 3. GUI apps and OrbStack

What gets installed and why: [`APPS.md`](APPS.md).

1. Install the apps every reinstall gets, then pick from the rest. 06 and 07 ask about each app and skip the ones already installed; apps marked off are asked about only with `--all`. For App Store picks, sign into the **App Store** app first.
   ```sh
   # No questions: the apps you always want
   ./install/05-install-apps.sh

   # Asks about each: other apps (vendor download, App Store, or their download page)
   ./install/06-install-optional-apps.sh

   # Asks about each: Safari extensions (App Store); turn them on in Safari > Settings > Extensions
   ./install/07-install-safari-extensions.sh
   ```
2. Install **OrbStack** by hand from https://orbstack.dev. Open it once and let it install its command-line tools (`orb`, `orbctl`, `docker`, `kubectl` into `/usr/local/bin`; it asks for an admin password). Its machines come in step 4.
3. Link the VS Code CLI and install the curated extensions:
   ```sh
   # VS Code CLI link and extensions
   ./install/08-vscode-extensions.sh
   ```

**On the photo machine only**, also run the photo apps script. It asks about Lightroom Classic and Photoshop, which install through Adobe Creative Cloud:
```sh
# Photo machine only: asks about each photo app and opens its download page
./install/09-install-photo-apps.sh
```

### 4. Restore the rest from the backup

Nothing comes back unasked: only what the manifest lists, and of that only what you pick. Quit Claude (the app and any `claude` session), iTerm2, VS Code, Obsidian, Zed, Viscosity and Insomnia, then from Terminal.app:

```sh
# The plan: each item, and whether it is new here, the same or different; changes nothing
./bin/homedir-restore
```

```sh
# Restore by group and by path
./bin/homedir-restore --only claude,apps,vault,projects,~/.config/zed/,~/.config/mise/config.toml
```

```sh
# Or item by item: restore, skip, diff, keep the backup's copy beside yours, a directory whole or file by file
./bin/homedir-restore --guided
```

- `--only` takes groups (`secrets work config claude apps vault projects personal`), paths in the backup (`~/x`, or a `~/BACKUP_FOLDER/home/x` path pasted from a listing; a directory or a file) and Claude Code MCP servers (`mcp:NAME`). `--guided` walks every group, or the `--only` list; `vault`, `projects` and `personal` go whole. `--all` restores every group at once and `--dry-run` shows the plan for `--only` or `--all`.
- Your configs come back over the copies homedir made in step 2. Afterwards `homedir-sync` shows which differ from homedir's and copies either way. From a Mac not set up from homedir (like the old Homebrew one), keep homedir's and take over only what's personal: its `.zprofile` loads Homebrew and its `.zshrc` has no `mise activate`.
- A file in both places gets the backup's copy. The restore deletes nothing, never replaces a symlink (homedir's links stay) and leaves repos already in `~/projects` alone; the summary lists what it left. A directory leaves out the manifest items inside it, which come with their own group. An interrupted run resumes when you run it again.
- `secrets` and `work` get `go-rwx`. iTerm2's preferences, the keyboard shortcuts, the Dock and the input sources go through `defaults import` and take effect when you log out in step 5. MCP servers are merged into `~/.claude.json` (the ClickHouse ones with `work`, the rest with `claude`), and after `claude` it checks that the hooks, status line and vault path its settings name exist.
- Then apply what came back: `mise install` for tools a restored `~/.config/mise/config.toml` adds, and `orb restart docker` if the backup had `~/.orbstack/config/docker.json`. Anything the backup missed: copy it from Time Machine.

Then set up OrbStack and its machines, after `mise install` so the shims skip any CLI your mise config puts on the host:

```sh
# OrbStack's memory limit and start-at-login, Docker's credsStore (ecr-login), the dev machine and ~/.local/bin shims
# for its infra CLIs (aws, tf, ansible-playbook, helm, ...), then the clickhouse machine, left stopped
./install/10-setup-orbstack.sh
```

After adding or removing a CA in `~/.config/ca-certificates/`, provision `dev` again: `orb -m dev bash -s < conf/orbstack/provision-dev.sh`.

### 5. Log out, then set the rest by hand

Log out and back in: it applies step 2's keyboard settings and the shortcuts, Dock and input sources the restore imported. Then set by hand what the backup can't carry:

- **Menu bar items** (System Settings → Control Center): which icons show (Wi-Fi, Sound, battery percentage) and the clock's date and weekday.
- **Logitech mouse buttons and scrolling:** come from Logi Options+'s own settings backup (step 3).
- **Text replacements:** come back through iCloud. Shortcuts.app shortcuts do too, but only if its iCloud Sync is on (see [TODO.md](TODO.md)).

## Saving Mac state before reinstall

On the old Mac, from this checkout:

1. Attach an **APFS (Encrypted)** external drive, create today's backup folder on it and link it:
   ```sh
   # Today's folder on the drive, e.g. reinstall.2026-11-22
   mkdir -p /Volumes/<Drive>/reinstall.$(date +%F)
   ln -sfn /Volumes/<Drive>/reinstall.$(date +%F) ~/BACKUP_FOLDER
   ```
2. Optional: bring the config changes you want to keep into homedir, so the new Mac starts from them. Commit them on a branch and get them to `main` (step 4):
   ```sh
   # Compare the configs with homedir's, copy either way, then commit
   ./bin/homedir-sync
   ```
3. Run the backup script. It copies everything [`conf/backup-manifest.txt`](conf/backup-manifest.txt) lists into `~/BACKUP_FOLDER/home/`, laid out like `~` (`~/projects` without `node_modules`/`.venv`/`.terraform`). It also saves to `extra/` the user-scope Claude Code MCP servers and a full copy of `~/.claude.json` (never restored whole; a project-local MCP server is only in there), writes a git report of every repo and worktree, and puts its own copy of `homedir-restore` and the manifest next to them. To back up something new, add a line to the manifest in the group the restore should bring it back with.
   ```sh
   # Everything the manifest lists, work and personal (~/Documents, ~/Desktop, ~/Downloads) included;
   # --omit-work or --omit-personal leaves that group out
   ./bin/homedir-backup
   ```
4. Review `~/BACKUP_FOLDER/git-report/summary.txt` and push any branches you want in origin before wiping. homedir's own changes must be on its default branch on GitHub, because reinstall step 2 clones that.
5. Leave the Time Machine backup untouched as an emergency fallback.

## Keeping the Mac lean

1. **One tool per category:** OrbStack only (no Rancher Desktop, Colima, Podman, or Lima alongside it); `mise` + `uv` only (no Brew, `nvm`, `pyenv`, `rbenv`, `tfenv`); Insomnia only (no Bruno, Postman, Scalar).
2. **Keep host `mise` lean:** heavy or rarely used infra CLIs live in the `dev` machine ([`conf/orbstack/provision-dev.sh`](conf/orbstack/provision-dev.sh)), which can be wiped and rebuilt.
3. **Periodic cleanup:** `homedir-prune` prunes `mise`, `uv`, Go build and test caches, Docker and old Claude Code CLI binaries, and prints how to recreate the `dev` and `clickhouse` machines from scratch.
4. **Skip vendor updater daemons:** Adobe Creative Cloud, Canon EOS Webcam Utility, JetBrains Toolbox and WiFiman, unless actively needed.

## Rolling back to Lima

OrbStack is the current choice; Lima stays only as an emergency rollback. Quit and delete `OrbStack.app`, run `./install/90-optional-setup-lima.sh` and open a new shell. It installs Lima and a standalone Docker CLI, creates the `docker`, `clickhouse` and `dev` VMs from `conf/lima/_templates/`, links the same VM shims (`bin/dev` finds `limactl` by itself) and points `DOCKER_HOST` at the `docker` VM. Lima has no host `kubectl`: use `dev kubectl`.
