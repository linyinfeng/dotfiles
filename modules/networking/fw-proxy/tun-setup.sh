#!@shell@

ip="@iproute2@/bin/ip"
iptables="@iptables@/bin/iptables"

route_table="@routeTable@"
tun_dev="@tunDev@"
fwmark="@fwmark@"
class_id="@classId@"

"$ip" route add default dev "$tun_dev" table "$route_table"
"$ip" rule add fwmark "$fwmark" lookup "$route_table"

"$iptables" -t mangle -I OUTPUT -m cgroup --cgroup "$class_id" -j MARK --set-xmark "$fwmark"
