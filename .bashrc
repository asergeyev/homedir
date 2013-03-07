# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

source /usr/local/go/misc/bash/go

function myssh {
	printf "\033]2;ssh @$1\007"
	env TERM=xterm /usr/bin/ssh $*
}

function mysudo {
	printf "\033]2;sudo @$HOSTNAME\007"
	env TERM=xterm /usr/bin/sudo $*
}

alias ssh="myssh"
alias sudo="mysudo"

if [ -n "$DISPLAY" -a "$TERM" == "xterm" ]; then
	TERM=xterm-256color
	export TERM
fi

if [ "$TERM" == "xterm-256color" ]; then
	MC_SKIN=my256
	export MC_SKIN
fi


export EDITOR="/usr/bin/vim"

function parse_git_branch {
        git rev-parse --git-dir &> /dev/null
        git_status="$(git status 2> /dev/null)"
        branch_pattern="^# On branch ([^${IFS}]*)"
        remote_pattern="# Your branch is (.*) of"
        diverge_pattern="# Your branch and (.*) have diverged"
        if [[ ! ${git_status} =~ "working directory clean" ]]; then
                git_status="$(git status . 2> /dev/null)"
                if [[ ! ${git_status} =~ "working directory clean" ]]; then
                    state="⚡⚡"
                else
                    state="⚡"
                fi
        fi
        # add an else if or two here if you want to get more specific
        if [[ ${git_status} =~ ${remote_pattern} ]]; then
                if [[ ${BASH_REMATCH[1]} == "ahead" ]]; then
                        remote="↑"
                else
                        remote="↓"
                fi
        fi
        if [[ ${git_status} =~ ${diverge_pattern} ]]; then
                remote="↕"
        fi
        if [[ ${git_status} =~ ${branch_pattern} ]]; then
                branch=${BASH_REMATCH[1]}
                echo " (${branch})${remote}${state}"
        fi
}

PS1='\u@:\W$(parse_git_branch)\$ '

