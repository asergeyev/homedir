#!/bin/bash -x

cd $(dirname $0)
SRC=$(pwd)

chsh -s /bin/bash

cd $HOME
mkdir -p .local/bin
cd .local/bin

ls $SRC/bin | xargs -I% -n1 ln -fs $SRC/bin/% .

ls $SRC/conf/*/install.sh | xargs -n1 $SHELL

cd $SRC
git checkout -b $HOSTNAME
