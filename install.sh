#!/bin/bash

cd $(dirname $0)
SRC=$(pwd)

cd $HOME
rm -f .bash_profile
rm -f .bashrc
rm -f .profile
rm -f .tmux.conf

ln -s $SRC/.bash_profile .
ln -s $SRC/.bashrc .
ln -s $SRC/.profile .
ln -s $SRC/.tmux.conf .

mkdir -p .local
cd .local
rm -f bin || exit
ln -s $SRC/bin .
