{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  thisHostCfg = asCfg.mesh.thisHost;

  xfrmIfId = hostCfg: 4242420000 + lib.head hostCfg.indices;
  xfrmIfIdString = hostCfg: "${toString (xfrmIfId hostCfg)}";
  xfrmIfName = name: hostCfg: "${asCfg.mesh.interfaces.namePrefix}-i${name}";
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
                Priority = asCfg.mesh.routingTable.priority;
              };
            }
            {
              routingPolicyRuleConfig = {
                To = asCfg.cidrV6;
                Table = asCfg.mesh.routingTable.id;
                Priority = asCfg.mesh.routingTable.priority;
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
            lib.lists.map (a: "${a}/32") thisHostCfg.addressesV4
            ++ lib.lists.map (a: "${a}/128") thisHostCfg.addressesV6;
        };
      };
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
            ${asCfg.mesh.bird.babelInterfaceConfig}
          };
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (pattern: ifCfg: ''
            interface "${pattern}" {
              type ${ifCfg.type};
              ${ifCfg.extraConfig}
            };
          '')
          asCfg.mesh.extraInterfaces)}
        }
      '';
      networking.firewall.allowedUDPPorts = [
        config.ports.babel
      ];
    }

    # IPSec/IKEv2 mesh
    (lib.mkIf asCfg.mesh.ipsec.enable {
      services.strongswan-swanctl = {
        enable = true;
        swanctl = {
          connections = let
            mkConnection = peerName: hostCfg:
              lib.nameValuePair "mesh-peer-${peerName}" {
                # https://docs.strongswan.org/docs/5.9/swanctl/swanctlConf.html
                # As an initiator, the first non-range/non-subnet is used to initiate the connection to.
                remote_addrs =
                  (
                    if thisHostCfg.endpointsV6 != null
                    then hostCfg.endpointsV6
                    else []
                  )
                  ++ (
                    if thisHostCfg.endpointsV4 != null
                    then hostCfg.endpointsV4
                    else []
                  )
                  ++ [
                    "%any" # allow connection from anywhere
                  ];
                # sign round authentication
                local.main = {
                  auth = "pubkey";
                  certs = ["${asCfg.mesh.ipsec.hostCertFile}"];
                  id = "${thisHostCfg.name}.li7g.com";
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
      environment.etc."swanctl/ecdsa/key.pem".source = asCfg.mesh.ipsec.hostCertKeyFile;
      environment.etc."/swanctl/x509ca/ca.pem".source = asCfg.mesh.ipsec.caCertFile;

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

      # firewall settings
      networking.firewall.allowedUDPPorts = with config.ports; [
        ipsec-ike
        ipsec-nat-traversal
      ];
      networking.firewall.extraCommands = ''
        ip46tables --append nixos-fw --protocol 50 --jump nixos-fw-accept # IPSec ESP
        ip46tables --append nixos-fw --protocol 51 --jump nixos-fw-accept # IPSec AH
      '';
    })
  ])
