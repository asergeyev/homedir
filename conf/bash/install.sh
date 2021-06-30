#!/bin/bash


cd $(dirname $0)
SRC=$(pwd)

cd $HOME

[ -f .profile ] && [ ! -L .profile ] && mv -f .profile .profile.bak
[ -f .bashrc ] && [ ! -L .bashrc ] && rm -f .bashrc
[ -f .bash_funcs ] && [ ! -L .bash_funcs ] && rm -f .bash_funcs

# we don't want these around:
rm -f .bash_profile
rm -f .zshrc

ln -fs $SRC/profile .profile
ln -fs $SRC/funcs .bash_funcs
ln -fs $SRC/rc  .bashrc

