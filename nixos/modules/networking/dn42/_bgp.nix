{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  bgpCfg = cfg.bgp;
  asCfg = cfg.autonomousSystem;
in
  lib.mkIf (cfg.enable && bgpCfg.enable) (
    lib.mkMerge [
      # common bird configuration
      {
        services.bird2.config = lib.mkOrder 150 ''
          # bgp configurations

          ipv4 table bgp_v4 { }
          ipv6 table bgp_v6 { }

          function is_self_net_v4() {
            return net ~ OWNNETSETv4;
          }

          function is_self_net_v6() {
            return net ~ OWNNETSETv6;
          }

          function is_valid_network_v4() {
            return net ~ [
              172.20.0.0/14{21,29}, # dn42
              172.20.0.0/24{28,32}, # dn42 Anycast
              172.21.0.0/24{28,32}, # dn42 Anycast
              172.22.0.0/24{28,32}, # dn42 Anycast
              172.23.0.0/24{28,32}, # dn42 Anycast
              172.31.0.0/16+,       # ChaosVPN
              10.100.0.0/14+,       # ChaosVPN
              10.127.0.0/16{16,32}, # neonetwork
              10.0.0.0/8{15,24}     # Freifunk.net
            ];
          }
          function is_valid_network_v6() {
            return net ~ [
              fd00::/8{44,64} # ULA address space as per RFC 4193
            ];
          }

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

          protocol kernel kernel_bgp_v4 {
            kernel table ${toString bgpCfg.routingTable.id};
            ipv4 {
                table bgp_v4;
                import none;
                export filter {
                    if source = RTS_STATIC then reject;
                    krt_prefsrc = OWNIPv4;
                    accept;
                };
            };
          }
          protocol kernel kernel_bgp_v6 {
            kernel table ${toString bgpCfg.routingTable.id};
            ipv6 {
                table bgp_v6;
                import none;
                export filter {
                    if source = RTS_STATIC then reject;
                    krt_prefsrc = OWNIPv6;
                    accept;
                };
            };
          };
          protocol static static_bgp_v4 {
            route OWNNETv4 reject;
            ipv4 {
              table bgp_v4;
              import all;
              export none;
            };
          }
          protocol static static_bgp_v6 {
            route OWNNETv6 reject;
            ipv6 {
              table bgp_v6;
              import all;
              export none;
            };
          }

          template bgp dnpeers {
            local as OWNAS;
            path metric 1;
            ipv4 {
              table bgp_v4;
              import filter {
                if is_valid_network_v4() && !is_self_net_v4() then {
                  if (roa_check(dn42_roa_v4, net, bgp_path.last) != ROA_VALID) then {
                    print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                    reject;
                  } else accept;
                } else reject;
              };
              export filter { if is_valid_network_v4() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
              import table;
              next hop self;
              igp table mesh_v4;
            };
            ipv6 {
              table bgp_v6;
              import filter {
                if is_valid_network_v6() && !is_self_net_v6() then {
                  if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
                    print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                    reject;
                  } else accept;
                } else reject;
              };
              export filter { if is_valid_network_v6() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
              import table;
              igp table mesh_v6;
            };
          }
        '';
        networking.firewall.allowedTCPPorts = [
          config.ports.bgp
        ];
      }

      # routing tables
      {
        systemd.network.config.routeTables = {
          ${bgpCfg.routingTable.name} = bgpCfg.routingTable.id;
          ${bgpCfg.peering.routingTable.name} = bgpCfg.peering.routingTable.id;
        };
        systemd.network.networks = {
          ${cfg.interfaces.dummy.name} = {
            routingPolicyRules = [
              {
                routingPolicyRuleConfig = {
                  Family = "both";
                  Table = bgpCfg.peering.routingTable.id;
                  Priority = bgpCfg.peering.routingTable.priority;
                };
              }
              {
                routingPolicyRuleConfig = {
                  Family = "both";
                  Table = bgpCfg.routingTable.id;
                  Priority = bgpCfg.routingTable.priority;
                };
              }
            ];
          };
        };
      }

      # local gortr server
      {
        systemd.services.gortr-dn42 = {
          script = ''
            ${pkgs.gortr}/bin/gortr \
              -cache "https://dn42.burble.com/roa/dn42_roa_46.json" \
              -verify=false \
              -checktime=false \
              -bind :${toString bgpCfg.gortr.port} \
              -metrics.addr :${toString bgpCfg.gortr.metricPort}
          '';
          serviceConfig = {
            DynamicUser = true;
          };
          wantedBy = ["multi-user.target"];
        };
      }

      # internel bgp peers
      {
        services.bird2.config = let
          bgpEnabledHostCfgs = lib.filter (hostCfg: hostCfg.bgp.enable) (lib.attrValues asCfg.mesh.peerHosts);
        in
          # multiprotocol bgp
          lib.mkOrder 200 (lib.concatMapStringsSep "\n" (hostCfg: ''
              protocol bgp ibgp_${hostCfg.name} from dnpeers {
                neighbor ${hostCfg.preferredAddressV6} as ${toString asCfg.number};
              }
            '')
            bgpEnabledHostCfgs);
      }

      # eternal bgp peers
      {
        # devices
        systemd.network.netdevs =
          lib.mapAttrs' (
            peerName: peerCfg:
              lib.nameValuePair
              peerCfg.tunnel.interface.name
              (
                if (peerCfg.tunnel.type == "wireguard")
                then {
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
                      wireguardPeerConfig = {
                        Endpoint = "${peerCfg.endpoint.address}:${toString peerCfg.endpoint.port}";
                        PublicKey = peerCfg.wireguard.remotePublicKey;
                        AllowedIPs = peerCfg.wireguard.allowedIps;
                        PersistentKeepalive = peerCfg.wireguard.persistentKeepAlive;
                      };
                    }
                  ];
                }
                else throw "unreachable"
              )
          )
          bgpCfg.peering.peers;
        environment.systemPackages = with pkgs; [
          wireguard-tools
        ];
        # links
        systemd.network.networks =
          lib.mapAttrs' (
            peerName: peerCfg:
              lib.nameValuePair
              peerCfg.tunnel.interface.name
              {
                matchConfig = {
                  Name = peerCfg.tunnel.interface.name;
                };
                addresses =
                  lib.lists.map (address: {
                    addressConfig = {
                      Address = "${address}/32";
                      Peer = "${peerCfg.linkAddresses.v4.peer}/32";
                      Scope = "link";
                    };
                  })
                  asCfg.mesh.thisHost.addressesV4
                  ++ lib.lists.map (address: {
                    addressConfig = {
                      Address = "${address}/128";
                      Peer = "${peerCfg.linkAddresses.v6.peer}/128";
                      Scope = "link";
                    };
                  })
                  asCfg.mesh.thisHost.addressesV6
                  ++ [
                    {
                      addressConfig = {
                        Address = "${peerCfg.linkAddresses.v6.linkLocal}/64";
                        Scope = "link";
                      };
                    }
                  ];
                networkConfig = {
                  LinkLocalAddressing = "no"; # disable link local autoconfiguration
                };
                # TODO wait for https://github.com/NixOS/nixpkgs/pull/230890
                # tokenBucketFilterConfig = lib.mkIf peerCfg.trafficControl.enable {
                #   Rate = peerCfg.trafficControl.rate;
                #   BurstBytes = peerCfg.trafficControl.burst;
                # };
                extraConfig = ''
                  [TokenBucketFilter]
                  Rate=${peerCfg.trafficControl.rate}
                  BurstBytes=${peerCfg.trafficControl.burst}
                  LatencySec=${peerCfg.trafficControl.latency}
                '';
              }
          )
          bgpCfg.peering.peers;
        services.bird2.config = lib.mkOrder 250 (lib.concatMapStringsSep "\n" (peerCfg: ''
          ${lib.optionalString (peerCfg.linkAddresses.v4.bgpNeighbor != null) ''
            protocol bgp ebgp_${peerCfg.bird.protocol.baseName}_v4 from dnpeers {
              neighbor ${peerCfg.linkAddresses.v4.bgpNeighbor} as ${toString peerCfg.remoteAutonomousSystem.number};
            }
          ''}
          ${lib.optionalString (peerCfg.linkAddresses.v6.bgpNeighbor != null) ''
            protocol bgp ebgp_${peerCfg.bird.protocol.baseName}_v6 from dnpeers {
              neighbor ${peerCfg.linkAddresses.v6.bgpNeighbor}%${peerCfg.tunnel.interface.name} as ${toString peerCfg.remoteAutonomousSystem.number};
            }
          ''}
        '') (lib.attrValues bgpCfg.peering.peers));
      }
    ]
  )
