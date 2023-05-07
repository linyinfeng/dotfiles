{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  hostName = config.networking.hostName;
  allHosts = config.lib.self.data.hosts;
  enabledHosts = lib.filterAttrs (_name: hostData: hostData.dn42_host_indices != []) allHosts;
  enabled = enabledHosts ? ${hostName};
  thisHost = enabledHosts.${hostName};
  otherHosts = lib.filterAttrs (name: _: name != hostName) enabledHosts;

  xfrmIfId = hostData: 4242420000 + lib.head hostData.dn42_host_indices;
  xfrmIfIdString = hostData: "${toString (xfrmIfId hostData)}";
  xfrmIfName = name: hostData: "${cfg.mesh.interfaces.namePrefix}-${name}";
in {
  options = {
    networking.dn42 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = enabled;
      };
      dummy.name = lib.mkOption {
        type = lib.types.str;
        default = "dn42";
      };
      mesh = {
        interfaces.namePrefix = lib.mkOption {
          type = lib.types.str;
          default = "mesh";
        };
        routingTable = lib.mkOption {
          type = lib.types.int;
          default = 200;
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable) (lib.mkMerge [
    # sysctl
    {
      boot.kernel.sysctl = {
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
      };
    }

    # network management tools
    # and compatibility issues
    {
      systemd.network.enable = true;
      networking.networkmanager.unmanaged = [
        cfg.dummy.name
      ];
    }
    (lib.mkIf config.networking.fw-proxy.tproxy.enable {
      services.strongswan-swanctl.strongswan.extraConfig = ''
        charon {
          # tproxy's routing table routes everything to lo
          ignore_routing_tables = ${config.networking.fw-proxy.tproxy.routingTable}
        }
      '';
    })

    # dummy interface
    {
      systemd.network.netdevs = {
        ${cfg.dummy.name} = {
          netdevConfig = {
            Name = cfg.dummy.name;
            Kind = "dummy";
          };
        };
      };
      systemd.network.networks = {
        ${cfg.dummy.name} = {
          matchConfig = {
            Name = cfg.dummy.name;
          };
          address =
            lib.lists.map (a: "${a}/32") thisHost.dn42_v4_addresses
            ++ lib.lists.map (a: "${a}/128") thisHost.dn42_v6_addresses;
          routingPolicyRules = [
            {
              routingPolicyRuleConfig = {
                To = config.lib.self.data.dn42_v4_cidr;
                Table = cfg.mesh.routingTable;
              };
            }
            {
              routingPolicyRuleConfig = {
                To = config.lib.self.data.dn42_v6_cidr;
                Table = cfg.mesh.routingTable;
              };
            }
          ];
        };
      };
    }

    # Route-based IPSec/IKEv2 mesh
    {
      services.strongswan-swanctl = {
        enable = true;
        swanctl = {
          connections = let
            mkConnection = peerName: hostData:
              lib.nameValuePair "mesh-peer-${peerName}" {
                remote_addrs =
                  hostData.endpoints_v4
                  ++ hostData.endpoints_v6
                  ++ [
                    "%any" # allow connection from anywhere
                  ];
                # sign round authentication
                local.main = {
                  auth = "pubkey";
                  certs = [config.sops.secrets."ike_cert_pem".path];
                  id = "${hostName}.li7g.com";
                };
                remote.main = {
                  auth = "pubkey";
                  id = "${peerName}.li7g.com";
                };
                children.dn42 = {
                  start_action = "trap";
                  # trap traffic using XFRM interface id
                  if_id_in = xfrmIfIdString hostData;
                  if_id_out = xfrmIfIdString hostData;
                  local_ts = ["0.0.0.0/0" "::/0"];
                  remote_ts = ["0.0.0.0/0" "::/0"];
                };
              };
          in
            lib.mapAttrs' mkConnection otherHosts;
          authorities.main.cacert = "ca.pem";
        };
      };
      environment.etc."swanctl/ecdsa/key.pem".source = config.sops.secrets."ike_private_key_pem".path;
      environment.etc."/swanctl/x509ca/ca.pem".text = config.lib.self.data.ca_cert_pem;

      # mesh interfaces
      systemd.network.netdevs =
        lib.mapAttrs' (
          peerName: hostData:
            lib.nameValuePair
            (xfrmIfName peerName hostData)
            {
              netdevConfig = {
                Name = xfrmIfName peerName hostData;
                Kind = "xfrm";
              };
              xfrmConfig = {
                InterfaceId = xfrmIfId hostData;
                Independent = true;
              };
            }
        )
        otherHosts;
      systemd.network.networks =
        lib.mapAttrs' (
          peerName: hostData:
            lib.nameValuePair
            (xfrmIfName peerName hostData)
            {
              matchConfig = {
                Name = xfrmIfName peerName hostData;
              };
              linkConfig = {
                Multicast = true;
              };
            }
        )
        otherHosts;

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
      services.bird2 = {
        enable = true;
        config = let
          # use the first ipv4 address as router id
          routeId = lib.elemAt thisHost.dn42_v4_addresses 0;
        in ''
          router id ${routeId};

          protocol device {
          }

          ipv4 table mesh4 { }
          ipv6 sadr table mesh6 { }

          protocol direct directmesh {
            interface "${cfg.dummy.name}";
            ipv4 {
              table mesh4;
              import all;
              export none;
            };
            ipv6 sadr {
              table mesh6;
              import all;
              export none;
            };
          }
          protocol kernel kernelmesh4 {
            kernel table ${toString cfg.mesh.routingTable};
            ipv4 {
              table mesh4;
              export filter {
                krt_prefsrc = ${lib.elemAt thisHost.dn42_v4_addresses 0};
                accept;
              };
              import none;
            };
          }
          protocol kernel kernelmesh6 {
            kernel table ${toString cfg.mesh.routingTable};
            ipv6 sadr {
              table mesh6;
              export filter {
                krt_prefsrc = ${lib.elemAt thisHost.dn42_v6_addresses 0};
                accept;
              };
              import none;
            };
          }
          protocol babel babelmesh {
            randomize router id;
            ipv4 {
              table mesh4;
              import all;
              export all;
            };
            ipv6 sadr {
              table mesh6;
              import all;
              export all;
            };
            interface "${cfg.mesh.interfaces.namePrefix}-*" {
              type tunnel;
              rtt cost 1024;
              rtt max 1024 ms;
            };
          }
        '';
      };
      networking.firewall.allowedUDPPorts = [
        config.ports.babel
      ];
    }
  ]);
}
