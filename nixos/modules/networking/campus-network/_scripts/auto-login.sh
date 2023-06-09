#!@shell@
# shellcheck shell=bash

set +e

login="@campusNetLogin@"
curl="@curl@/bin/curl"
interval="@intervalSec@"
max_time="@maxTimeSec@"

function test_and_login {
  echo -n "curl --ipv4 'http://captive.apple.com': "
  if
    "$curl" --ipv4 http://captive.apple.com --silent --show-error --max-time "$max_time" |
      grep Success >/dev/null
  then
    # do nothing
    echo "already logged in"
  else
    echo "no internet, try login"
    "$login"
  fi
}
while true; do
  test_and_login
  sleep "$interval"
done
