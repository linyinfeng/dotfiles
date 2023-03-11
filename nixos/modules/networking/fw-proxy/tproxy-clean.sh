#!@shell@

export PATH="@iproute2@/bin:@nftables@/bin:$PATH"

route_table="@routeTable@"
fwmark="@fwmark@"
cgroup="@cgroup@"
nft_table="@nftTable@"

set -x

# delete nftables
nft delete table inet $nft_table

# delete cgroup
rmdir "/sys/fs/cgroup/$cgroup"

# delete route tables
ip rule delete fwmark "$fwmark" table "$route_table"
ip -4 route delete local default dev lo table "$route_table"
ip -6 route delete local default dev lo table "$route_table"

true # always success
