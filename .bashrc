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
alias grep="grep --line-buffered"
alias more='less'
alias lc="wc -l"
alias zlc="zcat | wc -l"
alias f="cut -f "
alias xargs-c="xargs -n1 -I% bash -c"
alias ff="find . -type f"

if /bin/sort --help | grep -q parallel; then
    alias sort="/bin/sort --parallel 5 -S 3G"
else
    alias sort="/bin/sort -S 3G"
fi

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
	TERM=xterm-256color
	export TERM
fi

if which mc >/dev/null 2>&1; then
	if [ "$TERM" == "xterm-256color" ] && [ -f /usr/share/mc/skins/xoria256.ini ]; then
		MC_SKIN=xoria256
		export MC_SKIN
	fi
fi

if which vim >/dev/null 2>&1; then
	export EDITOR="/usr/bin/vim"
fi

if `java -version 2>&1 | grep -q OpenJDK`; then
	export JAVA_HOME=/usr/lib/jvm/jre
else
	export JAVA_HOME=/usr/java/latest
fi


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

if [ -d ~/.python ]; then 
	VIRTUAL_ENV_DISABLE_PROMPT=1
	. ~/.python/bin/activate
fi

if [ -d ~/.perl5 ]; then
	[ $SHLVL -eq 1 ] && eval "$(perl -I~/perl5/lib/perl5 -Mlocal::lib)"
fi


if [ -d ~/.local/bin ]; then
	export PATH=$HOME/.local/bin:$PATH
fi

if [ -d /usr/local/go/bin ]; then
	export GOBOOTSTRAP=/usr/local/go
	export PATH=$PATH:/usr/local/go/bin
	export GOPATH=$HOME/go
	alias gorun="go run"
elif [ -f /usr/bin/go ]; then
	export GOPATH=$HOME/go
	alias gorun="go run"
fi

