#!@shell@
# shellcheck shell=bash

export PATH="@iproute2@/bin:@nftables@/bin:$PATH"

tproxy_port="@tproxyPort@"
routing_table="@routingTable@"
fwmark="@fwmark@"
rule_priority="@rulePriority@"
nft_table="@nftTable@"
bypass_cgroup="@bypassCgroup@"
bypass_cgroup_level="@bypassCgroupLevel@"
max_level="@maxCgroupLevel@"
cgroup="@cgroup@"
all_cgroups=(@allCgroups@)
proxied_interfaces=(@proxiedInterfaces@)

set -ex

# setup route tables
ip -4 route add local default dev lo table "$routing_table"
ip -6 route add local default dev lo table "$routing_table"
ip -4 rule add fwmark "$fwmark" table "$routing_table" priority "$rule_priority"
ip -6 rule add fwmark "$fwmark" table "$routing_table" priority "$rule_priority"

# setup cgroup
mkdir "/sys/fs/cgroup/$cgroup"

# setup nftables
nft --file - <<EOF
table inet $nft_table
delete table inet $nft_table

table inet $nft_table {
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
      ::1/128,  # loopback
      fc00::/7, # private
      fe80::/10 # link-local
    }
  }

  set proxied-interfaces {
    typeof iif
    counter
  }

  chain prerouting {
    type filter hook prerouting priority mangle; policy accept;

    mark $fwmark \
      meta l4proto {tcp, udp} \
      tproxy to :$tproxy_port \
      counter \
      accept \
      comment "tproxy and accept marked packets (marked by the output chain)"

    jump filter

    meta l4proto {tcp, udp} \
      iif @proxied-interfaces \
      tproxy to :$tproxy_port \
      mark set $fwmark \
      counter
  }

  chain output {
    type route hook output priority mangle; policy accept;

    comment "marked packets will be routed to lo"

    socket cgroupv2 level $bypass_cgroup_level "$bypass_cgroup" \
      counter \
      return \
      comment "bypass packets of proxy service"

    jump filter
  }

  chain filter {
    # TODO enchilada's kernel does not support fib
    # fib daddr type local accept
    ip  daddr @reserved-ip  accept
    ip6 daddr @reserved-ip6 accept

    @extraFilterRules@
  }
}
EOF

while ! nft list table inet fw-tproxy; do
  echo "wait table inet fw-tproxy appear..."
  sleep 1
done

for level in $(seq 1 $max_level); do
  nft add set inet "$nft_table" cgroups-level"$level" "{" typeof socket cgroupv2 level "$level" \; "}"
  nft add rule inet "$nft_table" output \
    meta l4proto '{tcp, udp}' \
    socket cgroupv2 level "$level" @cgroups-level"$level" \
    meta mark set $fwmark
done

for cgroup in "${all_cgroups[@]}"; do
  "@tproxyCgroup@" add "$cgroup"
done

for if in "${proxied_interfaces[@]}"; do
  "@tproxyInterface@" add "$if"
done
