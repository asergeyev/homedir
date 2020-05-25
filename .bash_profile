# Source global definitions
if [[ -f /etc/bashrc ]]; then
	source /etc/bashrc
fi

if [[ -f /etc/bash.bashrc ]]; then
	source /etc/bash.bashrc
fi

if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi

if [[ -f ~/.bashlocal ]]; then
	source ~/.bashlocal
fi

PS1='[\u@\h \W]\$ '
