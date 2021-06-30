#!/bin/bash

cd $(dirname $0)
SRC=$(pwd)

cd $HOME
rm -f .bashrc
rm -f .bash_profile
rm -f .bash_funcs
rm -f .profile
rm -f .tmux.conf
rm -f .zshrc

ln -s $SRC/bash/rc .bashrc
ln -s $SRC/bash/funcs .bash_funcs
ln -s $SRC/.profile .
ln -s $SRC/.tmux.conf .

mkdir -p .local/bin
cd .local/bin
ls $SRC/bin | xargs -I% -n1 ln -fs $SRC/bin/% .

git checkout -b $HOSTNAME
