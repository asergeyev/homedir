#!/bin/bash -x

cd $(dirname $0)
SRC=$(pwd)

cd $HOME


# only if it's real file
[ -f .gitconfig ] && [ ! -L .gitconfig ] &&  mv .gitconfig .gitconfig.bak

ln -sf $SRC/config .gitconfig

mkdir -p .config/git
cd .config/git

[ -f ignore ] && [ ! -L ignore ] &&  mv ignore ignore.bak
ln -sf $SRC/ignore  .