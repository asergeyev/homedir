#!/bin/sh



cd $HOME
mkdir .nvm
export NVM_DIR="$HOME/.nvm"
IMPORT="/usr/local/opt/nvm/nvm.sh"
if [ ! -x "/usr/local/opt" ]; then
    IMPORT=`which nvm.sh`
fi
. $IMPORT

nvm install 12
nvm use 12

if brew ls --versions yarn; then brew upgrade yarn; else brew install yarn; fi


rbenv init

if [[ -d $HOME/.rbenv ]]; then 
    eval "$($HOME/.rbenv/bin/rbenv init -)"
    export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
fi


rbenv install 2.6.3
rbenv global 2.6.3



python3 -m venv ~/.venv
VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
VIRTUAL_ENV_DISABLE_PROMPT=1
. $HOME/.venv/bin/activate
if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
    . /usr/local/bin/virtualenvwrapper.sh
fi


mkdir -p $HOME/.local/bin
cd $HOME/.local/bin
wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O cloud_sql_proxy



