#!/bin/bash

# Copyright (C) 2016-2017 Claudio Luck <claudio.luck@gmail.com>
#
# MIT License

export LANG=C
export LC_ALL=C

function on_exit {
    [ -z "$NF" -o ! -e "$NF" ] || rm -f "$NF"
}
trap on_exit EXIT
NF=$(mktemp)

echo "# AUTOGENERATED proxy-trusts.pem" >$NF
echo "# Put certificates in /etc/nginx/proxy-trusts.pem.d" >>$NF
echo "#  and run UPDATE_proxy-trusts.sh" >>$NF
echo "" >>$NF

while read -d $'\0' PEM ; do
    echo "# Source: $(basename $PEM)" >>$NF
    cat $PEM >>$NF
    echo >>$NF
done < <(find /etc/nginx/proxy-trusts.pem.d/ -name \*.pem -print0)

# Always append one more:
echo "# Source: /etc/pki/tls/certs/support.ini.uzh.ch.crt.pem" >>$NF
cat /etc/pki/tls/certs/support.ini.uzh.ch.crt.pem >>$NF

if ! cmp --silent $NF /etc/nginx/proxy-trusts.pem ; then
    echo "/etc/nginx/proxy-trusts.pem changed, reloading server"
    mv -f $NF /etc/nginx/proxy-trusts.pem
    chmod 0400 /etc/nginx/proxy-trusts.pem
    chown nginx: /etc/nginx/proxy-trusts.pem
    restorecon /etc/nginx/proxy-trusts.pem
    systemctl reload nginx
fi