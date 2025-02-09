{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.networking.dn42;
  bgpCfg = cfg.bgp;
  asCfg = cfg.autonomousSystem;
in
lib.mkIf cfg.enable (
  lib.mkMerge [
    # common bird configuration
    {
      services.bird.config = lib.mkOrder 150 ''
        # dn42 bgp configurations

        ipv4 table dn42_bgp_v4 { }
        ipv6 table dn42_bgp_v6 { }

        roa4 table dn42_roa_v4;
        roa6 table dn42_roa_v6;
        protocol rpki rtr_dn42 {
          roa4 { table dn42_roa_v4; };
          roa6 { table dn42_roa_v6; };
          remote "localhost";
          port ${toString config.ports.gortr};
          refresh 600;
          retry 60;
        }

        function dn42_is_self_net_v4() {
          return net ~ DN42OWNNETSETv4;
        }

        function dn42_is_self_net_v6() {
          return net ~ DN42OWNNETSETv6;
        }

        function dn42_is_valid_network_v4() {
          return net ~ [
            172.20.0.0/14{21,29}, # dn42
            172.20.0.0/24{28,32}, # dn42 Anycast
            172.21.0.0/24{28,32}, # dn42 Anycast
            172.22.0.0/24{28,32}, # dn42 Anycast
            172.23.0.0/24{28,32}, # dn42 Anycast
            172.31.0.0/16+,       # ChaosVPN
            10.100.0.0/14+,       # ChaosVPN
            10.127.0.0/16{16,32}, # NeoNetwork
            10.0.0.0/8{15,24}     # Freifunk.net
          ];
        }
        function dn42_is_valid_network_v6() {
          return net ~ [
            fd00::/8{44,64} # ULA address space as per RFC 4193
          ];
        }

        # https://dn42.eu/howto/Bird-communities
        # propagation:
        #   for latency pick max(received_route.latency, link_latency)
        #   for encryption and bandwidth pick min between received BGP community and peer link

        function dn42_update_latency(int link_latency) {
          pair set latency_set = [(64511, 1..9)];
          pair new_latency = add(filter(bgp_community, latency_set), (64511, link_latency)).max;
          bgp_community = add(delete(bgp_community, latency_set), new_latency);
          return new_latency;
        }

        function dn42_update_bandwidth(int link_bandwidth) {
          pair set bandwidth_set = [(64511, 21..29)];
          pair new_bandwidth = add(filter(bgp_community, bandwidth_set), (64511, link_bandwidth)).min;
          bgp_community = add(delete(bgp_community, bandwidth_set), new_bandwidth);
          return new_bandwidth;
        }

        function dn42_update_crypto(int link_crypto) {
          pair set crypto_set = [(64511, 31..34)];
          pair new_crypto = add(filter(bgp_community, crypto_set), (64511, link_crypto)).min;
          bgp_community = add(delete(bgp_community, crypto_set), new_crypto);
          return new_crypto;
        }

        function dn42_update_communities(int link_latency; int link_bandwidth; int link_crypto)
        {
          pair dn42_latency = dn42_update_latency(link_latency);
          pair dn42_bandwidth = dn42_update_bandwidth(link_bandwidth);
          pair dn42_crypto = dn42_update_crypto(link_crypto);
          return true;
        }

        ${
          if bgpCfg.community.dn42.region != null then
            "define DN42_REGION = ${toString bgpCfg.community.dn42.region};"
          else
            ""
        }
        ${
          if bgpCfg.community.dn42.country != null then
            "define DN42_COUNTRY = ${toString bgpCfg.community.dn42.country};"
          else
            ""
        }
        function dn42_add_region_country_communities()
        {
          ${if bgpCfg.community.dn42.region != null then "bgp_community.add((64511, DN42_REGION));" else ""}
          ${
            if bgpCfg.community.dn42.country != null then "bgp_community.add((64511, DN42_COUNTRY));" else ""
          }
          return true;
        }

        function dn42_bgp_import_filter_v4(
          bool update_community;
          int link_latency;
          int link_bandwidth;
          int link_crypto)
        {
          if dn42_is_valid_network_v4() && !dn42_is_self_net_v4() then {
            if (roa_check(dn42_roa_v4, net, bgp_path.last) != ROA_VALID) then {
              print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
              reject;
            } else {
              # roa_check(..) = ROA_VALID
              if update_community then dn42_update_communities(link_latency, link_bandwidth, link_crypto);
              accept;
            }
          } else reject;
        }

        function dn42_bgp_export_filter_v4(
          bool update_community;
          int link_latency;
          int link_bandwidth;
          int link_crypto
        ) {
          if dn42_is_valid_network_v4() && source ~ [RTS_STATIC, RTS_BGP] then {
            if source = RTS_STATIC then dn42_add_region_country_communities();
            if update_community then dn42_update_communities(link_latency, link_bandwidth, link_crypto);
            accept;
          } else reject;
        }

        function dn42_bgp_import_filter_v6(
          bool update_community;
          int link_latency;
          int link_bandwidth;
          int link_crypto)
        {
          if dn42_is_valid_network_v6() && !dn42_is_self_net_v6() then {
            if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
              print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
              reject;
            } else {
              # roa_check(..) = ROA_VALID
              if update_community then dn42_update_communities(link_latency, link_bandwidth, link_crypto);
              accept;
            }
          } else reject;
        }

        function dn42_bgp_export_filter_v6(
          bool update_community;
          int link_latency;
          int link_bandwidth;
          int link_crypto
        ) {
          if dn42_is_valid_network_v6() && source ~ [RTS_STATIC, RTS_BGP] then {
            if source = RTS_STATIC then dn42_add_region_country_communities();
            if update_community then dn42_update_communities(link_latency, link_bandwidth, link_crypto);
            accept;
          } else reject;
        }

        protocol kernel kernel_dn42_bgp_v4 {
          kernel table ${toString bgpCfg.routingTable.id};
          ipv4 {
              table dn42_bgp_v4;
              import none;
              export filter {
                  if source = RTS_STATIC then reject;
                  krt_prefsrc = DN42OWNIPv4;
                  accept;
              };
          };
        }
        protocol kernel kernel_dn42_bgp_v6 {
          kernel table ${toString bgpCfg.routingTable.id};
          ipv6 {
              table dn42_bgp_v6;
              import none;
              export filter {
                  if source = RTS_STATIC then reject;
                  krt_prefsrc = DN42OWNIPv6;
                  accept;
              };
          };
        };
        protocol static static_dn42_bgp_v4 {
          route DN42OWNNETv4 unreachable;
          ipv4 {
            table dn42_bgp_v4;
            import all;
            export none;
          };
        }
        protocol static static_dn42_bgp_v6 {
          route DN42OWNNETv6 unreachable;
          ipv6 {
            table dn42_bgp_v6;
            import all;
            export none;
          };
        }

        template bgp dn42peer {
          local as DN42OWNAS;
          path metric 1;
          ipv4 {
            table dn42_bgp_v4;
            import none;
            export none;
            import table;
            export table;
            next hop self ebgp;
            extended next hop;
            igp table mesh_v4;
            igp table mesh_v6;
          };
          ipv6 {
            table dn42_bgp_v6;
            import none;
            export none;
            import table;
            export table;
            extended next hop;
            igp table mesh_v4;
            igp table mesh_v6;
          };
        }
      '';
      networking.firewall.allowedTCPPorts = [ config.ports.bgp ];
    }

    # routing tables
    {
      systemd.network.config.routeTables = {
        ${bgpCfg.routingTable.name} = bgpCfg.routingTable.id;
      };
      systemd.network.networks = {
        "70-${cfg.interfaces.dummy.name}" = {
          routingPolicyRules = [
            {
              Family = "both";
              Table = bgpCfg.routingTable.id;
              Priority = bgpCfg.routingTable.priority;
            }
          ];
        };
      };
    }

    # dn42 bgp collector
    (lib.mkIf bgpCfg.collector.dn42.enable {
      # https://dn42.eu/services/Route-Collector
      services.bird.config = lib.mkOrder 200 ''
        # dn42 bgp route collector
        protocol bgp bgp_dn42_route_collector
        {
          local as DN42OWNAS;
          neighbor fd42:4242:2601:ac12::1 as 4242422602;

          multihop;
          ipv4 {
            add paths tx;
            import none;
            export filter {
              if ( dn42_is_valid_network_v4() && source ~ [ RTS_STATIC, RTS_BGP ] )
              then accept; else reject;
            };
          };
          ipv6 {
            add paths tx;
            import none;
            export filter {
              if ( dn42_is_valid_network_v6() && source ~ [ RTS_STATIC, RTS_BGP ] )
              then accept; else reject;
            };
          };
        }
      '';
    })

    # local gortr server
    {
      systemd.services.gortr-dn42 = {
        script = ''
          ${pkgs.gortr}/bin/gortr \
            -cache "https://dn42.burble.com/roa/dn42_roa_46.json" \
            -verify=false \
            -checktime=false \
            -bind :${toString bgpCfg.gortr.port} \
            -metrics.addr :${toString bgpCfg.gortr.metricPort} \
            -rtr.retry 10
        '';
        serviceConfig = {
          DynamicUser = true;
        };
        wantedBy = [ "multi-user.target" ];
      };
    }

    # internel bgp peers
    {
      services.bird.config =
        # multiprotocol bgp
        lib.mkOrder 200 (
          lib.concatMapStringsSep "\n" (hostCfg: ''
            protocol bgp ibgp_dn42_${hostCfg.name} from dn42peer {
              neighbor ${hostCfg.preferredAddressV6} as ${toString asCfg.number};
              ipv4 {
                import where dn42_bgp_import_filter_v4(false, 1, 29, 34);
                export where dn42_bgp_export_filter_v4(false, 1, 29, 34);
              };
              ipv6 {
                import where dn42_bgp_import_filter_v6(false, 1, 29, 34);
                export where dn42_bgp_export_filter_v6(false, 1, 29, 34);
              };
            }
          '') (lib.attrValues asCfg.peerHosts)
        );
    }

    # eternal bgp peers
    {
      # devices
      systemd.network.netdevs = lib.mapAttrs' (
        _peerName: peerCfg:
        lib.nameValuePair "70-${peerCfg.tunnel.interface.name}" (
          if (peerCfg.tunnel.type == "wireguard") then
            {
              netdevConfig = {
                Name = peerCfg.tunnel.interface.name;
                Kind = "wireguard";
              };
              wireguardConfig = {
                PrivateKeyFile = peerCfg.wireguard.localPrivateKeyFile;
                ListenPort = peerCfg.localPort;
              };
              wireguardPeers = [
                {
                  Endpoint = "${peerCfg.endpoint.address}:${toString peerCfg.endpoint.port}";
                  PublicKey = peerCfg.wireguard.remotePublicKey;
                  AllowedIPs = peerCfg.wireguard.allowedIps;
                  PersistentKeepalive = peerCfg.wireguard.persistentKeepAlive;
                }
              ];
            }
          else
            throw "unreachable"
        )
      ) bgpCfg.peering.peers;
      environment.systemPackages = with pkgs; [ wireguard-tools ];
      # links
      systemd.network.networks = lib.mapAttrs' (
        _peerName: peerCfg:
        lib.nameValuePair "70-${peerCfg.tunnel.interface.name}" {
          matchConfig = {
            Name = peerCfg.tunnel.interface.name;
          };
          addresses =
            lib.lists.map (address: {
              Address = "${address}/32";
              Peer = "${peerCfg.linkAddresses.v4.peer}/32";
              Scope = "link";
            }) asCfg.thisHost.addressesV4
            ++ lib.lists.map (address: {
              Address = "${address}/128";
              Peer = "${peerCfg.linkAddresses.v6.peer}/128";
              Scope = "link";
            }) asCfg.thisHost.addressesV6
            ++ [
              {
                Address = "${peerCfg.linkAddresses.v6.linkLocal}/64";
                Scope = "link";
              }
            ];
          networkConfig = {
            LinkLocalAddressing = "no"; # disable link local autoconfiguration
          };
          tokenBucketFilterConfig = lib.mkIf peerCfg.trafficControl.enable {
            Rate = peerCfg.trafficControl.rate;
            BurstBytes = peerCfg.trafficControl.burst;
            LatencySec = peerCfg.trafficControl.latency;
          };
        }
      ) bgpCfg.peering.peers;
      services.bird.config = lib.mkOrder 250 (
        lib.concatMapStringsSep "\n" (
          peerCfg:
          let
            communityEnable = if peerCfg.bgp.community.dn42.enable then "true" else "false";
            inherit (peerCfg.bgp.community.dn42) latency bandwidth crypto;
            communityArgs = "${communityEnable}, ${toString latency}, ${toString bandwidth}, ${toString crypto}";
          in
          ''
            ${lib.optionalString (peerCfg.linkAddresses.v4.bgpNeighbor != null) ''
              protocol bgp ebgp_dn42_${peerCfg.bird.protocol.baseName}_v4 from dn42peer {
                neighbor ${peerCfg.linkAddresses.v4.bgpNeighbor} as ${toString peerCfg.remoteAutonomousSystem.number};
                ipv4 {
                  import where dn42_bgp_import_filter_v4(${communityArgs});
                  export where dn42_bgp_export_filter_v4(${communityArgs});
                };
                ipv6 {
                  import where dn42_bgp_import_filter_v6(${communityArgs});
                  export where dn42_bgp_export_filter_v6(${communityArgs});
                };
              }
            ''}
            ${lib.optionalString (peerCfg.linkAddresses.v6.bgpNeighbor != null) ''
              protocol bgp ebgp_dn42_${peerCfg.bird.protocol.baseName}_v6 from dn42peer {
                neighbor ${peerCfg.linkAddresses.v6.bgpNeighbor}%${peerCfg.tunnel.interface.name} as ${toString peerCfg.remoteAutonomousSystem.number};
                ipv4 {
                  import where dn42_bgp_import_filter_v4(${communityArgs});
                  export where dn42_bgp_export_filter_v4(${communityArgs});
                };
                ipv6 {
                  import where dn42_bgp_import_filter_v6(${communityArgs});
                  export where dn42_bgp_export_filter_v6(${communityArgs});
                };
              }
            ''}
          ''
        ) (lib.attrValues bgpCfg.peering.peers)
      );
    }
  ]
)
