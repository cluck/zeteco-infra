#!/bin/bash

# Copyright (C) 2016-2017 Claudio Luck <claudio.luck@gmail.com>
#
# MIT License

export LANG=C
export LC_ALL=C

function on_exit {
    [ -z "$NF" -o ! -e "$NF" ] || rm -f "$NF"
    [ -z "$NC" -o ! -e "$NC" ] || rm -f "$NC"
}
trap on_exit EXIT
NF=$(mktemp)
NC=$(mktemp)

mkdir -p /etc/nginx/proxy-trusts.pem.d

while read -d $'\0' PEM ; do
    HN=$(basename $(basename "$PEM" .pem) .cert)
    openssl s_client -showcerts -connect "$HN":443 -CAfile "$PEM" >$NF 2>&1 </dev/null
    sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' $NF >$NC
    TEST=$(grep 'Verify return code' $NF | head -n1)
    echo "$HN: $TEST"
    if [ -s $NC ] && ! cmp --silent $NC $PEM ; then
        echo "$HN: Certificate has changed!"
        cp -f $NC ${PEM}.new
    elif [ ! -s $NC ] ; then
        cat $NF
    fi
done < <(find /etc/nginx/proxy-trusts.pem.d/ -name \*.pem -print0)

