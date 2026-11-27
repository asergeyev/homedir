# Interactive zsh configuration

# History: 200k timestamped lines shared across tabs (macOS /etc/zshrc keeps 1000, untimestamped).
# Repeats stay in the file (usage stats) but Ctrl-R skips them.
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
HISTSIZE=200000
SAVEHIST=200000
setopt EXTENDED_HISTORY SHARE_HISTORY HIST_IGNORE_SPACE HIST_IGNORE_DUPS HIST_FIND_NO_DUPS HIST_REDUCE_BLANKS

# Fast completion initialization (regenerate dump once per day)
autoload -Uz compinit
if [ -f "${ZDOTDIR:-$HOME}/.zcompdump" ] && [ -z "$(find "${ZDOTDIR:-$HOME}/.zcompdump" -mtime +1 2>/dev/null)" ]; then
  compinit -C
else
  compinit
fi

# mise (fast runtime & CLI switching — replaces nvm, pyenv, rbenv, tfenv)
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Aliases
alias sort="sort -S5G"
alias grep="grep --line-buffered"

function calc() {
  echo say "($*)" | perl -Mv5.20
}

# watch replacement (no Homebrew): watch [-n secs] cmd... ; quote pipelines: watch -n5 'ls | wc -l'
function watch() {
  local n=2
  case $1 in
    -n) n=$2; shift 2 ;;
    -n*) n=${1#-n}; shift ;;
  esac
  while :; do
    clear
    print -r -- "Every ${n}s: $*    $(date +%T)"
    echo
    eval "$*"
    sleep "$n"
  done
}

# iTerm2 shell integration (optional)
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"
