{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  bgpCfg = cfg.bgp;

  padDn42LowerNumber = n: let
    s = toString n;
    length = lib.strings.stringLength s;
  in
    if length < 4
    then lib.lists.replicate (4 - length) "0" ++ [s]
    else s;

  hostOptions = {
    name,
    config,
    ...
  }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
      bgp.enable = lib.mkEnableOption "bgp";
      indices = lib.mkOption {
        type = with lib.types; listOf int;
      };
      addressesV4 = lib.mkOption {
        type = with lib.types; listOf str;
      };
      addressesV6 = lib.mkOption {
        type = with lib.types; listOf str;
      };
      preferredAddressV4 = lib.mkOption {
        type = lib.types.str;
        default = lib.elemAt config.addressesV4 0;
      };
      preferredAddressV6 = lib.mkOption {
        type = lib.types.str;
        default = lib.elemAt config.addressesV6 0;
      };
      endpointsV4 = lib.mkOption {
        type = with lib.types; listOf str;
      };
      endpointsV6 = lib.mkOption {
        type = with lib.types; listOf str;
      };
    };
  };
  peerOptions = {
    name,
    config,
    ...
  }: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
      tunnel = {
        type = lib.mkOption {
          type = lib.types.enum ["wireguard"];
        };
        interface.name = lib.mkOption {
          type = lib.types.str;
          default = "dn42peer${config.remoteAutonomousSystem.dn42LowerNumberString}";
        };
      };
      remoteAutonomousSystem = {
        dn42LowerNumber = lib.mkOption {
          type = lib.types.int;
        };
        dn42LowerNumberString = lib.mkOption {
          type = lib.types.str;
          default = padDn42LowerNumber config.remoteAutonomousSystem.dn42LowerNumber;
          readOnly = true;
        };
        number = lib.mkOption {
          type = lib.types.int;
          default = asCfg.dn42HigherNumber + config.remoteAutonomousSystem.dn42LowerNumber;
        };
      };
      endpoint = {
        address = lib.mkOption {
          type = lib.types.str;
        };
        port = lib.mkOption {
          type = lib.types.port;
          default = bgpCfg.peering.defaults.localPortStart + asCfg.dn42LowerNumber;
        };
      };
      bird = {
        protocol.baseName = lib.mkOption {
          type = lib.types.str;
          default = config.remoteAutonomousSystem.dn42LowerNumberString;
        };
      };
      linkAddresses = {
        v4 = {
          bgpNeighbor = lib.mkOption {
            type = with lib.types; nullOr str;
          };
          peer = lib.mkOption {
            type = with lib.types; str;
          };
        };
        v6 = {
          bgpNeighbor = lib.mkOption {
            type = with lib.types; nullOr str;
          };
          peer = lib.mkOption {
            type = with lib.types; str;
          };
          linkLocal = lib.mkOption {
            type = lib.types.str;
            default = bgpCfg.peering.defaults.linkAddresses.v6.local;
          };
        };
      };
      localPort = lib.mkOption {
        type = lib.types.port;
        default = bgpCfg.peering.defaults.localPortStart + config.remoteAutonomousSystem.dn42LowerNumber;
      };
      wireguard = {
        remotePublicKey = lib.mkOption {
          type = with lib.types; nullOr str;
          default = null;
        };
        allowedIps = lib.mkOption {
          type = with lib.types; listOf str;
          default = bgpCfg.peering.defaults.wireguard.allowedIps;
        };
        localPrivateKeyFile = lib.mkOption {
          type = lib.types.str;
          default = bgpCfg.peering.defaults.wireguard.localPrivateKeyFile;
        };
      };
    };
  };
in {
  options = {
    networking.dn42 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      bgp = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = asCfg.mesh.thisHost.bgp.enable;
        };
        routingTable = {
          id = lib.mkOption {
            type = lib.types.int;
            default = 201;
          };
          name = lib.mkOption {
            type = lib.types.str;
            default = "bgp-dn42";
          };
        };
        gortr = {
          port = lib.mkOption {
            type = lib.types.port;
            default = 8282;
          };
          metricPort = lib.mkOption {
            type = lib.types.port;
            default = 8080;
          };
        };
        peering = {
          defaults = {
            linkAddresses.v6.local = lib.mkOption {
              type = lib.types.str;
              default = "fe80::${toString asCfg.dn42LowerNumber}";
            };
            localPortStart = lib.mkOption {
              type = lib.types.port;
            };
            wireguard = {
              localPrivateKeyFile = lib.mkOption {
                type = lib.types.str;
                default = bgpCfg.peering.default.wireguard.localPrivateKeyFile;
                description = ''
                  File containing wireguard private key.
                  Must be readable by systemd-networkd.
                '';
              };
              allowedIps = lib.mkOption {
                type = with lib.types; listOf str;
                # https://dn42.eu/howto/Bird2
                default = [
                  "fe80::/10" # link local unicast

                  "172.20.0.0/14" # dn42
                  "172.31.0.0/16" # ChaosVPN
                  "10.0.0.0/8" # ChaosVPN, neonetwork, and Freifunk.net
                  "fd00::/8" # ULA address space as per RFC 4193
                ];
              };
            };
          };
          peers = lib.mkOption {
            type = with lib.types; attrsOf (submodule peerOptions);
            default = {};
          };
          routingTable = {
            id = lib.mkOption {
              type = lib.types.int;
              default = 202;
            };
            name = lib.mkOption {
              type = lib.types.str;
              default = "peer-dn42";
            };
          };
        };
      };
      bird = {
        routerId = lib.mkOption {
          type = lib.types.str;
          default = cfg.autonomousSystem.mesh.thisHost.preferredAddressV4;
        };
      };
      interfaces = {
        dummy.name = lib.mkOption {
          type = lib.types.str;
          default = "dn42";
        };
      };
      autonomousSystem = {
        dn42HigherNumber = lib.mkOption {
          type = lib.types.int;
          default = 4242420000;
        };
        dn42LowerNumber = lib.mkOption {
          type = lib.types.int;
        };
        dn42LowerNumberString = lib.mkOption {
          type = lib.types.str;
          default = padDn42LowerNumber asCfg.dn42LowerNumber;
          readOnly = true;
        };
        number = lib.mkOption {
          type = lib.types.int;
          default = asCfg.dn42HigherNumber + asCfg.dn42LowerNumber;
        };
        cidrV4 = lib.mkOption {
          type = lib.types.str;
        };
        cidrV6 = lib.mkOption {
          type = lib.types.str;
        };
        mesh = {
          me = lib.mkOption {
            type = lib.types.str;
            default = config.networking.hostName;
          };
          interfaces.namePrefix = lib.mkOption {
            type = lib.types.str;
            default = "mesh";
          };
          routingTable = {
            id = lib.mkOption {
              type = lib.types.int;
              default = 200;
            };
            name = lib.mkOption {
              type = lib.types.str;
              default = "mesh-dn42";
            };
          };
          hosts = lib.mkOption {
            type = with lib.types; attrsOf (submodule hostOptions);
            default = {};
          };
          thisHost = lib.mkOption {
            type = lib.types.submodule hostOptions;
            default = asCfg.mesh.hosts.${asCfg.mesh.me};
            readOnly = true;
          };
          peerHosts = lib.mkOption {
            type = with lib.types; attrsOf (submodule hostOptions);
            default = lib.filterAttrs (key: _: key != asCfg.mesh.me) asCfg.mesh.hosts;
            readOnly = true;
          };
        };
      };
    };
  };

  imports = [
    ./_autonomous-system.nix
    ./_bgp.nix
  ];
  config = lib.mkIf (cfg.enable) {
    boot.kernel.sysctl = {
      "net.ipv6.conf.default.forwarding" = 1;
      "net.ipv4.conf.default.forwarding" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
      "net.ipv4.conf.all.forwarding" = 1;
    };
    networking.firewall.checkReversePath = false;

    # basic bird2 configurations
    services.bird2 = {
      enable = true;
      config = lib.mkOrder 50 ''
        # common configurations

        define OWNAS = ${toString cfg.autonomousSystem.number};
        define OWNIPv4 = ${cfg.autonomousSystem.mesh.thisHost.preferredAddressV4};
        define OWNIPv6 = ${cfg.autonomousSystem.mesh.thisHost.preferredAddressV6};
        define OWNNETv4 = ${cfg.autonomousSystem.cidrV4};
        define OWNNETv6 = ${cfg.autonomousSystem.cidrV6};
        define OWNNETSETv4 = [${cfg.autonomousSystem.cidrV4}+];
        define OWNNETSETv6 = [${cfg.autonomousSystem.cidrV6}+];

        router id ${cfg.bird.routerId};
        protocol device device_main { }
      '';
    };

    # dummy interface
    systemd.network.netdevs = {
      ${cfg.interfaces.dummy.name} = {
        netdevConfig = {
          Name = cfg.interfaces.dummy.name;
          Kind = "dummy";
        };
      };
    };
    systemd.network.networks = {
      ${cfg.interfaces.dummy.name} = {
        matchConfig = {
          Name = cfg.interfaces.dummy.name;
        };
      };
    };
  };
}
