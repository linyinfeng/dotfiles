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
                  Table = bgpCfg.routingTable.id;
                };
              }
              {
                routingPolicyRuleConfig = {
                  Family = "both";
                  Table = bgpCfg.peering.routingTable.id;
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
          lib.mkOrder 200 (lib.concatMapStringsSep "\n" (hostCfg: ''
              protocol bgp ibgp_${hostCfg.name}_v4 from dnpeers {
                neighbor ${hostCfg.preferredAddressV4} as ${toString asCfg.number};
              }
              protocol bgp ibgp_${hostCfg.name}_v6 from dnpeers {
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
                      Endpoint = "${peerCfg.endpoint.address}:${peerCfg.endpoint.port}";
                      PublicKey = peerCfg.wireguard.remotePublicKey;
                      AllowedIPs = peerCfg.wireguard.allowedIps;
                    }
                  ];
                }
                else throw "unreachable"
              )
          )
          bgpCfg.peering.peers;
        # links
        systemd.network.networks =
          lib.mapAttrs' (
            peerName: peerCfg:
              lib.nameValuePair
              peerCfg.tunnel.interface.name
              {
                mathConfig = {
                  Name = peerCfg.tunnel.interface.name;
                };
                addresses = [
                  {
                    addressConfig = {
                      Address = "${peerCfg.linkLocal.v6.local}/128";
                      Scope = "link";
                    };
                  }
                ];
                routes = [
                  {
                    routeConfig = {
                      Destination = "${peerCfg.linkLocal.v4.remote}/32";
                      Scope = "link";
                      PreferredSource = "${asCfg.mesh.thisHost.preferredAddressV4}";
                    };
                  }
                ];
                networkConfig = {
                  LinkLocalAddressing = "no"; # disable link local autoconfiguration
                };
              }
          )
          bgpCfg.peering.peers;
        services.bird2.config = lib.mkOrder 250 (lib.concatMapStringsSep "\n" (peerCfg: ''
          protocol bgp bgp_${config.remoteAutonomousSystem.dn42LowerNumberString}_v4 from dnpeers {
            neighbor ${peerCfg.linkAddresses.v4.remote} as ${toString peerCfg.remoteAutonomousSystem.number};
          }
          protocol bgp bgp_${config.remoteAutonomousSystem.dn42LowerNumberString}_v6 from dnpeers {
            neighbor ${peerCfg.linkAddresses.v6.remote}%${peerCfg.tunnel.interface.name} as ${toString peerCfg.remoteAutonomousSystem.number};
          }
        '') (lib.attrValues bgpCfg.peering.peers));
      }
    ]
  )
