{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;

  xfrmIfId = hostCfg: 4242420000 + lib.head hostCfg.indices;
  xfrmIfIdString = hostCfg: "${toString (xfrmIfId hostCfg)}";
  xfrmIfName = name: hostCfg: "${asCfg.mesh.interfaces.namePrefix}-${name}";
in
  lib.mkIf (cfg.enable) (lib.mkMerge [
    # network management tools and compatibility issues
    {
      systemd.network.enable = true;
      networking.networkmanager.unmanaged = [
        cfg.interfaces.dummy.name
      ];
      services.strongswan-swanctl.strongswan.extraConfig = lib.mkIf config.networking.fw-proxy.tproxy.enable ''
        charon {
          # tproxy's routing table routes everything to lo
          ignore_routing_tables = ${config.networking.fw-proxy.tproxy.routingTable}
        }
      '';
    }

    # routing table
    {
      systemd.network.config.routeTables = {
        ${asCfg.mesh.routingTable.name} = asCfg.mesh.routingTable.id;
      };
      systemd.network.networks = {
        ${cfg.interfaces.dummy.name} = {
          routingPolicyRules = [
            {
              routingPolicyRuleConfig = {
                To = asCfg.cidrV4;
                Table = asCfg.mesh.routingTable.id;
              };
            }
            {
              routingPolicyRuleConfig = {
                To = asCfg.cidrV6;
                Table = asCfg.mesh.routingTable.id;
              };
            }
          ];
        };
      };
    }

    # address of the dummy interface
    {
      systemd.network.networks = {
        ${cfg.interfaces.dummy.name} = {
          address =
            lib.lists.map (a: "${a}/32") asCfg.mesh.thisHost.addressesV4
            ++ lib.lists.map (a: "${a}/128") asCfg.mesh.thisHost.addressesV6;
        };
      };
    }

    # route-based IPSec/IKEv2 mesh
    {
      services.strongswan-swanctl = {
        enable = true;
        swanctl = {
          connections = let
            mkConnection = peerName: hostCfg:
              lib.nameValuePair "mesh-peer-${peerName}" {
                remote_addrs =
                  hostCfg.endpointsV4
                  ++ hostCfg.endpointsV6
                  ++ [
                    "%any" # allow connection from anywhere
                  ];
                # sign round authentication
                local.main = {
                  auth = "pubkey";
                  certs = [config.sops.secrets."ike_cert_pem".path];
                  id = "${asCfg.mesh.thisHost.name}.li7g.com";
                };
                remote.main = {
                  auth = "pubkey";
                  id = "${peerName}.li7g.com";
                };
                children.dn42 = {
                  start_action = "trap";
                  # trap traffic using XFRM interface id
                  if_id_in = xfrmIfIdString hostCfg;
                  if_id_out = xfrmIfIdString hostCfg;
                  local_ts = ["0.0.0.0/0" "::/0"];
                  remote_ts = ["0.0.0.0/0" "::/0"];
                };
              };
          in
            lib.mapAttrs' mkConnection asCfg.mesh.peerHosts;
          authorities.main.cacert = "ca.pem";
        };
      };
      environment.etc."swanctl/ecdsa/key.pem".source = config.sops.secrets."ike_private_key_pem".path;
      environment.etc."/swanctl/x509ca/ca.pem".text = config.lib.self.data.ca_cert_pem;

      # mesh interfaces
      systemd.network.netdevs =
        lib.mapAttrs' (
          peerName: hostCfg:
            lib.nameValuePair
            (xfrmIfName peerName hostCfg)
            {
              netdevConfig = {
                Name = xfrmIfName peerName hostCfg;
                Kind = "xfrm";
              };
              xfrmConfig = {
                InterfaceId = xfrmIfId hostCfg;
                Independent = true;
              };
            }
        )
        asCfg.mesh.peerHosts;
      systemd.network.networks =
        lib.mapAttrs' (
          peerName: hostCfg:
            lib.nameValuePair
            (xfrmIfName peerName hostCfg)
            {
              matchConfig = {
                Name = xfrmIfName peerName hostCfg;
              };
              linkConfig = {
                Multicast = true;
              };
            }
        )
        asCfg.mesh.peerHosts;

      # management tools
      environment.systemPackages = with pkgs; [
        strongswan
      ];

      # secrets
      sops.secrets."ike_cert_pem" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["strongswan-swanctl.service"];
      };
      sops.secrets."ike_private_key_pem" = {
        sopsFile = config.sops-file.terraform;
        restartUnits = ["strongswan-swanctl.service"];
      };

      # firewall settings
      networking.firewall.allowedUDPPorts = with config.ports; [
        ipsec-ike
        ipsec-nat-traversal
      ];
      networking.firewall.extraCommands = ''
        ip46tables --append nixos-fw --protocol 50 --jump nixos-fw-accept # IPSec ESP
        ip46tables --append nixos-fw --protocol 51 --jump nixos-fw-accept # IPSec AH
      '';
    }

    # bird
    {
      services.bird2.config = lib.mkOrder 100 ''
        # babel configurations
        ipv4 table mesh_v4 { }
        ipv6 table mesh_v6 { }

        protocol direct direct_mesh {
          interface "${cfg.interfaces.dummy.name}";
          ipv4 {
            table mesh_v4;
            import all;
            export none;
          };
          ipv6 {
            table mesh_v6;
            import all;
            export none;
          };
        }
        protocol kernel kernel_mesh_v4 {
          kernel table ${toString asCfg.mesh.routingTable.id};
          ipv4 {
            table mesh_v4;
            export filter {
              krt_prefsrc = OWNIPv4;
              accept;
            };
            import none;
          };
        }
        protocol kernel kernel_mesh_v6 {
          kernel table ${toString asCfg.mesh.routingTable.id};
          ipv6 {
            table mesh_v6;
            export filter {
              krt_prefsrc = OWNIPv6;
              accept;
            };
            import none;
          };
        }
        protocol babel babel_mesh {
          randomize router id;
          ipv4 {
            table mesh_v4;
            import all;
            export all;
          };
          ipv6 {
            table mesh_v6;
            import all;
            export all;
          };
          interface "${asCfg.mesh.interfaces.namePrefix}-*" {
            type tunnel;
            rtt cost 1024;
            rtt max 1024 ms;
          };
        }
      '';
      networking.firewall.allowedUDPPorts = [
        config.ports.babel
      ];
    }
  ])
