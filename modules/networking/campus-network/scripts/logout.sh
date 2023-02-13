#!@shell@

set -e

curl="@curl@/bin/curl"

$curl -X POST https://p.nju.edu.cn/api/portal/v1/logout --json "{}"
