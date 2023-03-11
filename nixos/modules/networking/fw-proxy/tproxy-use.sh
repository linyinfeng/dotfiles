#!@shell@

tproxy_use_pid="@tproxyUsePid@"

set -e
sudo "$tproxy_use_pid" $$ 2>&1 >/dev/null
exec "$@"
