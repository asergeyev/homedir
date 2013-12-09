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

function myssh {
	printf "\033]2;[*] ssh $*\007"
	env TERM=xterm /usr/bin/ssh $*
}

function mysshadd {
	printf "\033]2;[*] ssh-add $*\007"
	env TERM=xterm /usr/bin/ssh-add $*
}

function myscp {
	printf "\033]2;[*] scp $*\007"
	env TERM=xterm /usr/bin/scp $*
}

function mysudo {
	HOST=`hostname --long 2>/dev/null || hostname`
	printf "\033]2;[*] sudo $HOST\007"
	env TERM=xterm /usr/bin/sudo $*
}



