#!/bin/bash


brewOp() {
  echo $2 ...
  sleep 3
  if brew $1 ls --versions "$2"; then
    brew upgrade "$2"
  else
    brew install "$2"
  fi
}

brewIn()   { brewOp "" $1; }
brewCask() { brewOp "cask" $1; }


brewIn coreutils
brewIn curl
brewIn git


brewIn gnu-tar
brewIn go
brewIn jq
brewIn midnight-commander
brewIn rbenv
brewIn tmux
brewIn wget
brewIn xz
brewIn gpg
brewIn htop
brewIn mysql-client


brewCask iterm2
brewCask bitbar
brewCask zoomus
brewCask insomnia
brewCask karabiner-elements
brewCask rescuetime
brewCask visual-studio-code
brewCask wireshark
brewCask google-chrome
brewCask google-cloud-sdk
#brewCask rstudio
#brewCask amazon-music
#brewCask spotify

brew tap homebrew/cask-fonts
brewCask font-fira-code
brewCask font-inconsolata


brewIn nvm
brewIn rbenv
brewIn perl
brewIn python3
brewIn cpanminus
brewIn vim

