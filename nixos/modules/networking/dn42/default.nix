{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  hostOptions = {
    name,
    config,
    ...
  }: {
    options = {
      enable = lib.mkEnableOption "this mesh host";
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
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
in {
  options = {
    networking.dn42 = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      bgp = {
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
        number = lib.mkOption {
          type = lib.types.int;
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
      config = lib.mkBefore ''
        # common configurations

        define OWNAS = ${toString cfg.autonomousSystem.number};
        define OWNIPv4 = ${cfg.autonomousSystem.mesh.thisHost.preferredAddressV4};
        define OWNIPv6 = ${cfg.autonomousSystem.mesh.thisHost.preferredAddressV6};
        define OWNNETv4 = ${cfg.autonomousSystem.cidrV4};
        define OWNNETv6 = ${cfg.autonomousSystem.cidrV6};
        define OWNNETSETv4 = [${cfg.autonomousSystem.cidrV4}+];
        define OWNNETSETv6 = [${cfg.autonomousSystem.cidrV6}+];

        router id ${cfg.bird.routerId};
        protocol device { }
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
