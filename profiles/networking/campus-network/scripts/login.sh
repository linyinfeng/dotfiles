#!@shell@

curl="@curl@/bin/curl"
username_file="@usernameFile@"
password_file="@passwordFile@"

username=$(cat "$username_file")
password=$(cat "$password_file")

$curl -X POST http://p.nju.edu.cn/portal_io/login \
  --data "username=$username&password=$password"
