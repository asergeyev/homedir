if [ -d $HOME/.local/bin ]; then
	export PATH=$HOME/.local/bin:$PATH
fi

if [ -d /usr/local/go ]; then
	export PATH=$PATH:/usr/local/go/bin
	export GOROOT=/usr/local/go
	export GOPATH=$HOME/go
fi

if which firefox >/dev/null 2>&1; then
	export MOZ_TMPDIR=$HOME/Downloads/tmp
fi
