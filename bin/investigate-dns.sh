#!/bin/bash

NAME=$1

if [ -z "$NAME" ]; then
	echo "Usage: $0 DNSNAME [DNSRECURSIVE]"
	exit 1
fi

SERVER=$2
if [ -n  "$DNS" ]; then
	SERVER="@$DNS"
fi


check() {
ASK=$1
ANSW=$(dig $SERVER +trace +short +answer $ASK | tail -1)
if [ "$?" != "0" ]; then
	echo "Error while asking '$NAME' check your recursive please"
	exit 1
fi
IFS=' ' read -a AR <<< "$ANSW"
echo $ANSW "(reverse: $(dig +short -x ${AR[4]} | tr '\n' ' '))"
if [ "${AR[0]}" == "CNAME" ]; then
	check ${AR[1]}
fi
}


check $NAME
