{ lib }:
let
  inherit (lib.kernel)
    yes
    no
    module
    freeform
    ;
in
{
  # Linux/riscv 5.10.4 Kernel Configuration

  ### Networking options
  "NETFILTER" = yes; # Network packet filtering framework (Netfilter)

  ##### Core Netfilter Configuration
  "NETFILTER_NETLINK_ACCT" = module; # Netfilter NFACCT over NFNETLINK interface
  "NETFILTER_NETLINK_QUEUE" = module; # Netfilter NFQUEUE over NFNETLINK interface
  "NETFILTER_NETLINK_LOG" = module; # Netfilter LOG over NFNETLINK interface
  "NETFILTER_NETLINK_OSF" = module; # Netfilter OSF over NFNETLINK interface
  "NF_CONNTRACK" = module; # Netfilter connection tracking support
  "NF_CONNTRACK_MARK" = yes; # Connection mark tracking support
  "NF_CONNTRACK_SECMARK" = yes; # Connection tracking security mark support
  "NF_CONNTRACK_ZONES" = yes; # Connection tracking zones
  "NF_CONNTRACK_PROCFS" = yes; # Supply CT list in procfs (OBSOLETE)
  "NF_CONNTRACK_EVENTS" = yes; # Connection tracking events
  "NF_CONNTRACK_TIMEOUT" = yes; # Connection tracking timeout
  "NF_CONNTRACK_TIMESTAMP" = yes; # Connection tracking timestamping
  "NF_CONNTRACK_LABELS" = yes; # Connection tracking labels
  "NF_CT_PROTO_DCCP" = yes; # DCCP protocol connection tracking support
  "NF_CT_PROTO_SCTP" = yes; # SCTP protocol connection tracking support
  "NF_CT_PROTO_UDPLITE" = yes; # UDP-Lite protocol connection tracking support
  "NF_CONNTRACK_AMANDA" = module; # Amanda backup protocol support
  "NF_CONNTRACK_FTP" = module; # FTP protocol support
  "NF_CONNTRACK_H323" = module; # H.323 protocol support
  "NF_CONNTRACK_IRC" = module; # IRC protocol support
  "NF_CONNTRACK_NETBIOS_NS" = module; # NetBIOS name service protocol support
  "NF_CONNTRACK_SNMP" = module; # SNMP service protocol support
  "NF_CONNTRACK_PPTP" = module; # PPtP protocol support
  "NF_CONNTRACK_SANE" = module; # SANE protocol support
  "NF_CONNTRACK_SIP" = module; # SIP protocol support
  "NF_CONNTRACK_TFTP" = module; # TFTP protocol support
  "NF_CT_NETLINK" = module; # Connection tracking netlink interface
  "NF_CT_NETLINK_TIMEOUT" = module; # Connection tracking timeout tuning via Netlink
  "NF_CT_NETLINK_HELPER" = module; # Connection tracking helpers in user-space via Netlink
  "NF_NAT" = module; # Network Address Translation support
  "NF_TABLES" = module; # Netfilter nf_tables support
  "NF_TABLES_INET" = yes; # Netfilter nf_tables mixed IPv4/IPv6 tables support
  "NF_TABLES_NETDEV" = yes; # Netfilter nf_tables netdev tables support
  "NFT_NUMGEN" = module; # Netfilter nf_tables number generator module
  "NFT_CT" = module; # Netfilter nf_tables conntrack module
  "NFT_FLOW_OFFLOAD" = module; # Netfilter nf_tables hardware flow offload module
  "NFT_CONNLIMIT" = module; # Netfilter nf_tables connlimit module
  "NFT_LOG" = module; # Netfilter nf_tables log module
  "NFT_LIMIT" = module; # Netfilter nf_tables limit module
  "NFT_MASQ" = module; # Netfilter nf_tables masquerade support
  "NFT_REDIR" = module; # Netfilter nf_tables redirect support
  "NFT_NAT" = module; # Netfilter nf_tables nat module
  "NFT_TUNNEL" = module; # Netfilter nf_tables tunnel module
  "NFT_QUEUE" = module; # Netfilter nf_tables queue module
  "NFT_QUOTA" = module; # Netfilter nf_tables quota module
  "NFT_REJECT" = module; # Netfilter nf_tables reject support
  "NFT_COMPAT" = module; # Netfilter x_tables over nf_tables module
  "NFT_HASH" = module; # Netfilter nf_tables hash module
  "NFT_FIB_INET" = module; # Netfilter nf_tables fib inet support
  "NFT_XFRM" = module; # Netfilter nf_tables xfrm/IPSec security association matching
  "NFT_SOCKET" = module; # Netfilter nf_tables socket match support
  "NFT_OSF" = module; # Netfilter nf_tables passive OS fingerprint support
  "NFT_TPROXY" = module; # Netfilter nf_tables tproxy support
  "NFT_SYNPROXY" = module; # Netfilter nf_tables SYNPROXY expression support
  "NF_DUP_NETDEV" = module; # Netfilter packet duplication support
  "NFT_DUP_NETDEV" = module; # Netfilter nf_tables netdev packet duplication support
  "NFT_FWD_NETDEV" = module; # Netfilter nf_tables netdev packet forwarding support
  "NFT_FIB_NETDEV" = module; # Netfilter nf_tables netdev fib lookups support
  "NF_FLOW_TABLE_INET" = module; # Netfilter flow table mixed IPv4/IPv6 module
  "NF_FLOW_TABLE" = module; # Netfilter flow table module
  ##### end of Core Netfilter Configuration

  ##### IP: Netfilter Configuration
  "NF_SOCKET_IPV4" = module; # IPv4 socket lookup support
  "NF_TPROXY_IPV4" = module; # IPv4 tproxy support
  "NF_TABLES_IPV4" = yes; # IPv4 nf_tables support
  "NFT_DUP_IPV4" = module; # IPv4 nf_tables packet duplication support
  "NFT_FIB_IPV4" = module; # nf_tables fib / ip route lookup support
  "NF_TABLES_ARP" = yes; # ARP nf_tables support
  "NF_DUP_IPV4" = module; # Netfilter IPv4 packet duplication to alternate destination
  "NF_LOG_ARP" = module; # ARP packet logging
  "NF_LOG_IPV4" = module; # IPv4 packet logging
  "NF_REJECT_IPV4" = module; # IPv4 packet rejection
  "NF_NAT_SNMP_BASIC" = module; # Basic SNMP-ALG support
  "IP_NF_IPTABLES" = module; # IP tables support (required for filtering/masq/NAT)
  "IP_NF_MATCH_AH" = module; # "ah" match support
  "IP_NF_MATCH_ECN" = module; # "ecn" match support
  "IP_NF_MATCH_RPFILTER" = module; # "rpfilter" reverse path filter match support
  "IP_NF_MATCH_TTL" = module; # "ttl" match support
  "IP_NF_FILTER" = module; # Packet filtering
  "IP_NF_TARGET_REJECT" = module; # REJECT target support
  "IP_NF_TARGET_SYNPROXY" = module; # SYNPROXY target support
  "IP_NF_NAT" = module; # iptables NAT support
  "IP_NF_TARGET_MASQUERADE" = module; # MASQUERADE target support
  "IP_NF_TARGET_NETMAP" = module; # NETMAP target support
  "IP_NF_TARGET_REDIRECT" = module; # REDIRECT target support
  "IP_NF_MANGLE" = module; # Packet mangling
  "IP_NF_TARGET_ECN" = module; # ECN target support
  "IP_NF_TARGET_TTL" = module; # "TTL" target support
  "IP_NF_RAW" = module; # raw table support (required for NOTRACK/TRACE)
  "IP_NF_SECURITY" = module; # Security table
  "IP_NF_ARPTABLES" = module; # ARP tables support
  "IP_NF_ARPFILTER" = module; # ARP packet filtering
  "IP_NF_ARP_MANGLE" = module; # ARP payload mangling
  ##### end of IP: Netfilter Configuration

  ##### IPv6: Netfilter Configuration
  "NF_SOCKET_IPV6" = module; # IPv6 socket lookup support
  "NF_TPROXY_IPV6" = module; # IPv6 tproxy support
  "NF_TABLES_IPV6" = yes; # IPv6 nf_tables support
  "NFT_DUP_IPV6" = module; # IPv6 nf_tables packet duplication support
  "NFT_FIB_IPV6" = module; # nf_tables fib / ipv6 route lookup support
  "NF_DUP_IPV6" = module; # Netfilter IPv6 packet duplication to alternate destination
  "NF_REJECT_IPV6" = module; # IPv6 packet rejection
  "NF_LOG_IPV6" = module; # IPv6 packet logging
  "IP6_NF_IPTABLES" = module; # IP6 tables support (required for filtering)
  "IP6_NF_MATCH_AH" = module; # "ah" match support
  "IP6_NF_MATCH_EUI64" = module; # "eui64" address check
  "IP6_NF_MATCH_FRAG" = module; # "frag" Fragmentation header match support
  "IP6_NF_MATCH_OPTS" = module; # "hbh" hop-by-hop and "dst" opts header match support
  "IP6_NF_MATCH_HL" = module; # "hl" hoplimit match support
  "IP6_NF_MATCH_IPV6HEADER" = module; # "ipv6header" IPv6 Extension Headers Match
  "IP6_NF_MATCH_MH" = module; # "mh" match support
  "IP6_NF_MATCH_RPFILTER" = module; # "rpfilter" reverse path filter match support
  "IP6_NF_MATCH_RT" = module; # "rt" Routing header match support
  "IP6_NF_MATCH_SRH" = module; # "srh" Segment Routing header match support
  "IP6_NF_TARGET_HL" = module; # "HL" hoplimit target support
  "IP6_NF_FILTER" = module; # Packet filtering
  "IP6_NF_TARGET_REJECT" = module; # REJECT target support
  "IP6_NF_TARGET_SYNPROXY" = module; # SYNPROXY target support
  "IP6_NF_MANGLE" = module; # Packet mangling
  "IP6_NF_RAW" = module; # raw table support (required for TRACE)
  "IP6_NF_SECURITY" = module; # Security table
  "IP6_NF_NAT" = module; # ip6tables NAT support
  "IP6_NF_TARGET_MASQUERADE" = module; # MASQUERADE target support
  "IP6_NF_TARGET_NPT" = module; # NPT (Network Prefix translation) target support
  ##### end of IPv6: Netfilter Configuration
  "NF_TABLES_BRIDGE" = module; # Ethernet Bridge nf_tables support
  "NFT_BRIDGE_META" = module; # Netfilter nf_table bridge meta support
  "NFT_BRIDGE_REJECT" = module; # Netfilter nf_tables bridge reject support
  "NF_CONNTRACK_BRIDGE" = module; # IPv4/IPV6 bridge connection tracking support
  "NETLINK_DIAG" = module; # NETLINK: socket monitoring interface
  ### end of Networking options
  # end of Linux/riscv 5.10.4 Kernel Configuration
}
