#!/bin/bash

UPGRADE=$1

brewOp() {
  if brew list $1 --versions "$2"; then
    if [[ -n "$UPGRADE" ]]; then
        echo $2 ...
        brew upgrade $1 "$2"
    fi
  else
    echo $2 ...
    brew install $1 "$2"
  fi
}

brewIn()   { brewOp "" $1; }
brewCask() { brewOp "--cask" $1; }


brewIn bash

if ! fgrep -q /usr/local/bin/bash /etc/shells ; then
    echo "/usr/local/bin/bash" | sudo tee -a /etc/shells > /dev/null
fi

brewIn coreutils
brewIn curl
brewIn git
brewIn gnu-tar
brewIn go
brewIn gpg
#brewIn htop
brewIn jq
brewIn midnight-commander
brewIn mysql-client
brewIn rustup
brewIn tmux
brewIn vim
brewIn wget
brewIn xz


brewCask alfred
brewCask bitbar
brewCask google-chrome
brewCask google-cloud-sdk
brewCask insomnia
brewCask iterm2
brewCask karabiner-elements
#brewCask rescuetime
brewCask rstudio
brewCask visual-studio-code
#brewCask wireshark
brewCask zoom

brew tap homebrew/cask-fonts
brewCask font-fira-code
brewCask font-inconsolata

#brewIn cpanminus
brewIn nvm
brewIn perl
brewIn pyenv
brewIn rbenv

