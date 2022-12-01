#!@shell@

export PATH="@iproute2@/bin:@nftables@/bin:$PATH"

tproxy_port="@tproxyPort@"
route_table="@routeTable@"
fwmark="@fwmark@"
cgroup="@cgroup@"
proxied_interfaces="@proxiedInterfaceElements@"
level1_cgroups='@level1CgroupElements@'
level2_cgroups='@level2CgroupElements@'

set -x

# setup route tables
ip rule add fwmark "$fwmark" table "$route_table"
ip -4 route add local default dev lo table "$route_table"
ip -6 route add local default dev lo table "$route_table"

# setup cgroup
mkdir "/sys/fs/cgroup/$cgroup"

# setup nftables
nft --file - <<EOF
table inet clash-tproxy
delete table inet clash-tproxy

table inet clash-tproxy {
  set reserved-ip {
    typeof ip daddr
    flags interval
    elements = {
      10.0.0.0/8,        # private
      100.64.0.0/10,     # private
      127.0.0.0/8,       # loopback
      169.254.0.0/16,    # link-local
      172.16.0.0/12,     # private
      192.0.0.0/24,      # private
      192.168.0.0/16,    # private
      198.18.0.0/15,     # private
      224.0.0.0/4,       # multicast
      255.255.255.255/32 # limited broadcast
    }
  }

  set reserved-ip6 {
    typeof ip6 daddr
    flags interval
    elements = {
      ::1/128,        # loopback
      fc00::/7,       # private
      fe80::/10       # link-local
    }
  }

  set proxied-interfaces {
    type ifname
    counter
    elements = { $proxied_interfaces }
  }

  set level1-cgroups {
    typeof socket cgroupv2 level 1
    counter
    elements = { $level1_cgroups }
  }

  set level2-cgroups {
    typeof  socket cgroupv2 level 2
    counter
    elements = { $level2_cgroups }
  }
  chain prerouting {
    type filter hook prerouting priority mangle; policy accept;
    fib daddr type local return
    ip  daddr @reserved-ip  return
    ip6 daddr @reserved-ip6 return
    @extraPreroutingRules@
    meta l4proto {tcp, udp} \
      iifname @proxied-interfaces \
      meta mark set $fwmark \
      tproxy to :$tproxy_port \
      counter
  }
  chain output {
    type route hook output priority mangle; policy accept;
    socket cgroupv2 level 2 "system.slice/clash-premium.service" counter return
    @extraOutputRules@
    meta l4proto {tcp, udp} \
      socket cgroupv2 level 1 @level1-cgroups \
      meta mark set $fwmark
    meta l4proto {tcp, udp} \
      socket cgroupv2 level 2 @level2-cgroups \
      meta mark set $fwmark
  }
}
EOF
