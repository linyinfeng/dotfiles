#!@shell@
# shellcheck shell=bash

tproxy_use_pid="@tproxyUsePid@"

set -e
sudo "$tproxy_use_pid" $$ >/dev/null 2>&1
exec "$@"
