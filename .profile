# show lines from M to N when called as "M:N filename"
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


# get list of fields from tsv header (line per column)
function fcl {
	head -1 $1 | tr '\t' '\n' | cat -n
}


function calc {
	A="say ($*)"
	perl -Mv5.18 -e "$A"
}


