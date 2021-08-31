#!@shell@

ip="@iproute2@/bin/ip"
iptables="@iptables@/bin/iptables"

route_table="@routeTable@"
class_id="@classId@"
fwmark="@fwmark@"

"$ip" rule delete fwmark "$fwmark" lookup "$route_table"
"$ip" route delete default table "$route_table"

"$iptables" -t mangle -D OUTPUT -m cgroup --cgroup "$class_id" -j MARK --set-xmark "$fwmark"
