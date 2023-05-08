{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  bgpCfg = cfg.bgp;
in
  lib.mkIf (cfg.enable) (lib.mkMerge [
    # common bird configuration
    {
      services.bird2.config = ''
        # bgp configurations

        ipv4 table bgp4 { }
        ipv6 table bgp6 { }

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

        protocol kernel kernelbgp4 {
          kernel table ${toString bgpCfg.routingTable.id};
          ipv4 {
              table bgp4;
              import none;
              export filter {
                  if source = RTS_STATIC then reject;
                  krt_prefsrc = OWNIPv4;
                  accept;
              };
          };
        }
        protocol kernel kernelbgp6 {
          kernel table ${toString bgpCfg.routingTable.id};
          ipv6 {
              table bgp6;
              import none;
              export filter {
                  if source = RTS_STATIC then reject;
                  krt_prefsrc = OWNIPv6;
                  accept;
              };
          };
        };
        protocol static staticbgp4 {
          route OWNNETv4 reject;
          ipv4 {
            table bgp4;
            import all;
            export none;
          };
        }
        protocol static staticbgp6 {
          route OWNNETv6 reject;
          ipv6 {
            table bgp6;
            import all;
            export none;
          };
        }

        template bgp dnpeers {
          local as OWNAS;
          path metric 1;
          ipv4 {
            import filter {
              if is_valid_network_v4() && !is_self_net_v4() then {
                if (roa_check(dn42_roa_v4, net, bgp_path.last) != ROA_VALID) then {
                  print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                  reject;
                } else accept;
              } else reject;
            };
            export filter { if is_valid_network_v4() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
            import limit 1000 action block;
          };
          ipv6 {
            import filter {
              if is_valid_network_v6() && !is_self_net_v6() then {
                if (roa_check(dn42_roa_v6, net, bgp_path.last) != ROA_VALID) then {
                  print "[dn42] ROA check failed for ", net, " ASN ", bgp_path.last;
                  reject;
                } else accept;
              } else reject;
            };
            export filter { if is_valid_network_v6() && source ~ [RTS_STATIC, RTS_BGP] then accept; else reject; };
            import limit 1000 action block;
          };
        }
      '';
      networking.firewall.allowedUDPPorts = [
        config.ports.bgp
      ];
    }

    # routing table
    {
      systemd.network.config.routeTables = {
        ${bgpCfg.routingTable.name} = bgpCfg.routingTable.id;
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
  ])
