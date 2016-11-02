# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	source /etc/bashrc
fi

if [ -f /etc/bash.bashrc ]; then
	source /etc/bash.bashrc
fi


if [ -f $HOME/.profile ]; then
	source $HOME/.profile
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

if sort --help | grep -q parallel; then
    alias sort="sort --parallel 5 -S 3G"
else
    alias sort="sort -S 3G"
fi

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
	TERM=xterm-256color
	export TERM
fi

if which mc >/dev/null 2>&1; then
	if [ "$TERM" == "xterm-256color" ]; then
		MC_SKIN=xoria256
		export MC_SKIN
	fi
fi

if which vim >/dev/null 2>&1; then
	export EDITOR="/usr/bin/vim"
fi

if which java >/dev/null 2>&1; then
	if `java -version 2>&1 | grep -q OpenJDK`; then
		export JAVA_HOME=/usr/lib/jvm/jre
	else
		export JAVA_HOME=/usr/java/latest
	fi
fi


if [ -d /opt/chef ]; then
	export PATH="$PATH:/opt/chef/embedded/bin"
	if [ -f $HOME/.chef/.profile ]; then
		source $HOME/.chef/.profile
	fi
fi

if [ -d $HOME/.rbenv ]; then 
	eval "$($HOME/.rbenv/bin/rbenv init -)"
	export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
fi

if [ -d $HOME/.python ]; then 
	VIRTUAL_ENV_DISABLE_PROMPT=1
	. $HOME/.python/bin/activate
	if [ -f /usr/local/bin/virtualenvwrapper.sh ]; then
		. /usr/local/bin/virtualenvwrapper.sh
	fi
fi

if [ -d $HOME/perl5 ]; then
	eval "$(perl -I $HOME/perl5/lib/perl5 -Mlocal::lib)"
fi

if [ -d $HOME/.local/bin ]; then
	export PATH=$HOME/.local/bin:$PATH
fi

if [ -x /usr/local/go/bin/go ]; then
	export GOPATH=$HOME/go
	export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin
elif [ -x /usr/local/bin/go ]; then
	export GOPATH=$HOME/go
	export PATH=$PATH:$GOPATH/bin
elif [ -x /usr/lib/golang/bin/go ]; then
	export GOPATH=$HOME/go
	export PATH=$PATH:/usr/lib/golang/bin:$GOPATH/bin
fi

