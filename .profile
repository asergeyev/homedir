function lcut {
	f=$1
	FN=$2
	if `echo "$f" | grep -q ':'`; then
		A0=$(echo "$f"| cut -d: -f1)
		A1=$(echo "$f"| cut -d: -f2)

		A0=${A0:-1}
		if [ -z "$A1" ]; then
			tail -n +$A0 $FN
		else
			tail -n +$A0 $FN | head -$(($A1 - $A0 + 1))
		fi
	else
		echo first argument should be "n:m", got \"$f\" >/dev/stderr
		return 1
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

function fcl {
	head -1 $1 | tr '\t' '\n' | cat -n
}

function mt {
	S=$(date +%s)
	X=$(($S / 3600))
	D=$(($X / 24))
	echo "$(($D/28))/$(($D % 28))/$(($X % 24))"
}
