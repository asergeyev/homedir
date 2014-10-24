# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	source /etc/bashrc
fi

if [ -f /etc/bash.bashrc ]; then
	source /etc/bash.bashrc
fi


if [ -f ~/.profile ]; then
	source ~/.profile
fi

alias ssh="myssh"
alias scp="myscp"
alias sudo="mysudo"
alias ssh-add="mysshadd"

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
	TERM=xterm-256color
	export TERM
fi

if which mc >/dev/null 2>&1; then
	if [ "$TERM" == "xterm-256color" ]; then
		MC_SKIN=my256
		export MC_SKIN
	fi
fi

if which vim >/dev/null 2>&1; then
	export EDITOR="/usr/bin/vim"
fi

if which git >/dev/null 2>&1; then
	PS1='\u@$(hostname -s):\W$(parse_git_branch)\$ '
fi



export JAVA_HOME=/usr/java/latest


if [ -d /opt/chef ]; then
	export PATH="$PATH:/opt/chef/embedded/bin"
	if [ -f ~/.chef/.profile ]; then
		source ~/.chef/.profile
	fi
fi

if [ -d ~/.rbenv ]; then 
   export  PATH="$HOME/.rbenv/bin:$PATH"
	eval "$(rbenv init -)"
fi

if [ -d $HOME/.local/bin ]; then
	export PATH=$HOME/.local/bin:$PATH
fi

if [ -d /usr/local/go ]; then
	export PATH=$PATH:/usr/local/go/bin
	export GOROOT=/usr/local/go
	export GOPATH=$HOME/go:/u/2014/go
fi

