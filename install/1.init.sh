#!/bin/bash -xe

sudo -v

which -s g++ || sudo xcode-select --install

which -s brew || bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew doctor

read -p "Press any key to update brew ..."
sleep 3

brew update

