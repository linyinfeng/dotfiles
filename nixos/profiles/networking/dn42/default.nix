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
  xfrmIfName = name: hostData: "${cfg.mesh.interfacePrefix}-${name}";
in {
  options = {
    networking.dn42 = {
      enable = {
        type = lib.types.bool;
        default = enabled;
      };
      interface = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "dn42";
        };
        routingTable = lib.mkOption {
          type = lib.types.int;
          default = 200;
        };
      };
      mesh = {
        interfacePrefix = lib.mkOption {
          type = lib.types.str;
          default = "mesh";
        };
      };
    };
  };
  config = lib.mkIf enabled (lib.mkMerge [
    # sysctl
    {
      boot.kernel.sysctl = {
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
      };
      networking.firewall.checkReversePath = false;
    }

    # interface
    {
      systemd.network.enable = true;
      systemd.network.netdevs = {
        dn42 = {
          netdevConfig = {
            Name = cfg.interface.name;
            Kind = "vrf";
          };
          vrfConfig = {
            Table = cfg.interface.routingTable;
          };
        };
      };
      systemd.network.networks = {
        dn42 = {
          matchConfig = {
            Name = cfg.interface.name;
          };
          networkConfig = {
            Address = thisHost.dn42_v4_addresses ++ thisHost.dn42_v6_addresses;
          };
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
                  if_id_in = xfrmIfIdString hostData;
                  if_id_out = xfrmIfIdString hostData;
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
            "mesh-peer-${peerName}"
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
            "mesh-peer-${peerName}"
            {
              matchConfig = {
                Name = xfrmIfName peerName hostData;
              };
              networkConfig = {
                VRF = cfg.interface.name;
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
        iptables --append nixos-fw --protocol 50 --jump nixos-fw-accept # IPSec ESP
        iptables --append nixos-fw --protocol 51 --jump nixos-fw-accept # IPSec AH
      '';
    }

    # bird
    {
      services.bird2 = {
        enable = true;
        config = ''
          protocol device {
          }

          ipv4 table mesh4 { }
          ipv6 sadr table mesh6 { }
          protocol kernel {
            kernel table ${toString cfg.interface.routingTable};
            ipv4 {
              table mesh4;
              export all;
              import all;
            };
          }
          protocol kernel {
            kernel table ${toString cfg.interface.routingTable};
            ipv6 sadr {
              table mesh6;
              export all;
              import all;
            };
          }
          protocol babel {
            vrf "${cfg.interface.name}";
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
            interface "${cfg.mesh.interfacePrefix}-*" {
              type wireless;
            };
          }
        '';
      };
    }
  ]);
}
