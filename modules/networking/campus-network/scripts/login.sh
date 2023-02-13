#!@shell@

set -e

curl="@curl@/bin/curl"
username_file="@usernameFile@"
password_file="@passwordFile@"

username=$(cat "$username_file")
password=$(cat "$password_file")

$curl -X POST https://p.nju.edu.cn/api/portal/v1/login \
  --json @- <<EOF
  {
    "username": "$username",
    "password": "$password"
  }
EOF
