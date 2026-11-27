# Non-interactive & login shell environment (VS Code, hooks, xbar, etc.)

# mise shims let non-interactive tools (VS Code, xbar, Claude hooks) find go, node, pnpm, uv, etc.
export PATH="$HOME/.local/share/mise/shims:$HOME/.local/bin:$HOME/go/bin:$PATH"

# OrbStack's command-line tools and completions (its own line; harmless before OrbStack is installed)
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

# Work settings (private Go modules, work aliases) live in ~/.zprofile-work: a commented template in homedir, your own
# copy from the backup. Sourced last, so what it sets wins.
if [ -f ~/.zprofile-work ]; then
  source ~/.zprofile-work
fi
