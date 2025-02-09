{ config, lib, ... }:
let
  cfg = config.networking.dn42;
  asCfg = cfg.autonomousSystem;
  bgpCfg = cfg.bgp;
  selfLib = config.lib.self;

  padDn42LowerNumber =
    n:
    let
      s = toString n;
      length = lib.strings.stringLength s;
    in
    if length < 4 then lib.lists.replicate (4 - length) "0" ++ [ s ] else s;

  # https://dn42.eu/howto/Bird-communities
  dn42RegionType =
    with lib.types;
    int
    // {
      description = "dn42 community region";
      # the range 41-70 is assigned to the region property
      check = v: int.check v && 41 <= v && v <= 70;
    };
  dn42CountryType =
    with lib.types;
    int
    // {
      description = "dn42 community country";
      # the range 1000-1999 is assigned to the country property
      check = v: int.check v && 1000 <= v && v <= 1999;
    };
  peerHostOptions =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        preferredAddressV4 = lib.mkOption { type = lib.types.str; };
        preferredAddressV6 = lib.mkOption { type = lib.types.str; };
      };
    };
  thisHostOptions =
    { ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = asCfg.me;
        };
        addressesV4 = lib.mkOption { type = with lib.types; listOf str; };
        addressesV6 = lib.mkOption { type = with lib.types; listOf str; };
        preferredAddressV4 = lib.mkOption { type = lib.types.str; };
        preferredAddressV6 = lib.mkOption { type = lib.types.str; };
      };
    };
  supportedTunnelTypes = [ "wireguard" ];
  peerOptions =
    { name, config, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        tunnel = {
          type = lib.mkOption { type = lib.types.enum supportedTunnelTypes; };
          interface.name = lib.mkOption {
            type = lib.types.str;
            default = "dn42peer${config.remoteAutonomousSystem.dn42LowerNumberString}";
          };
        };
        remoteAutonomousSystem = {
          dn42LowerNumber = lib.mkOption { type = lib.types.int; };
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
          address = lib.mkOption { type = lib.types.str; };
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
        bgp.community.dn42 = {
          enable = lib.mkEnableOption "dn42 bgp community";
          latency = lib.mkOption {
            type =
              with lib.types;
              int
              // {
                description = "dn42 community latency";
                check = v: int.check v && 0 < v && v < 10;
              };
            default = 1;
          };
          bandwidth = lib.mkOption {
            type =
              with lib.types;
              int
              // {
                description = "dn42 community bandwidth";
                check = v: int.check v && 20 < v && v < 30;
              };
            default = 24; # 100Mbps <= . < 1000Mbps
          };
          crypto = lib.mkOption {
            type =
              with lib.types;
              int
              // {
                description = "dn42 community crypto";
                check = v: int.check v && 30 < v && v < 35;
              };
            default = { wireguard = 34; }.${config.tunnel.type};
          };
        };
        linkAddresses = {
          v4 = {
            bgpNeighbor = lib.mkOption { type = with lib.types; nullOr str; };
            peer = lib.mkOption { type = with lib.types; str; };
          };
          v6 = {
            bgpNeighbor = lib.mkOption { type = with lib.types; nullOr str; };
            peer = lib.mkOption { type = with lib.types; str; };
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
          persistentKeepAlive = lib.mkOption {
            type = lib.types.int;
            default = bgpCfg.peering.defaults.wireguard.persistentKeepAlive;
          };
        };
        trafficControl = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = bgpCfg.peering.defaults.trafficControl.enable;
          };
          rate = lib.mkOption {
            type = lib.types.str;
            default = bgpCfg.peering.defaults.trafficControl.rate;
          };
          burst = lib.mkOption {
            type = lib.types.str;
            default = bgpCfg.peering.defaults.trafficControl.burst;
          };
          latency = lib.mkOption {
            type = lib.types.str;
            default = bgpCfg.peering.defaults.trafficControl.latency;
          };
        };
      };
    };
in
{
  options = {
    networking.dn42 = {
      enable = lib.mkEnableOption "dn42";
      bgp = {
        routingTable = {
          id = lib.mkOption { type = lib.types.int; };
          name = lib.mkOption {
            type = lib.types.str;
            default = "dn42-bgp";
          };
          priority = lib.mkOption { type = lib.types.int; };
        };
        gortr = {
          port = lib.mkOption { type = lib.types.port; };
          metricPort = lib.mkOption { type = lib.types.port; };
        };
        community.dn42 = {
          region = lib.mkOption { type = lib.types.nullOr dn42RegionType; };
          country = lib.mkOption { type = lib.types.nullOr dn42CountryType; };
        };
        collector.dn42.enable = lib.mkEnableOption "dn42 BGP collector";
        peering = {
          defaults = {
            linkAddresses.v6.local = lib.mkOption {
              type = lib.types.str;
              default = "fe80::${toString asCfg.dn42LowerNumber}";
            };
            localPortStart = lib.mkOption { type = lib.types.port; };
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
              persistentKeepAlive = lib.mkOption {
                type = lib.types.int;
                # set to 0 to disable
                default = 25;
              };
            };
            trafficControl = {
              enable = lib.mkEnableOption "traffic control";
              rate = lib.mkOption {
                type = lib.types.str;
                default = "5M"; # 5 Mbps
              };
              burst = lib.mkOption {
                type = lib.types.str;
                default = "1M"; # 1 MB
              };
              latency = lib.mkOption {
                type = lib.types.str;
                default = "100ms";
              };
            };
          };
          peers = lib.mkOption {
            type = with lib.types; attrsOf (submodule peerOptions);
            default = { };
          };
        };
      };
      bird = {
        routerId = lib.mkOption {
          type = lib.types.str;
          default = cfg.autonomousSystem.thisHost.preferredAddressV4;
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
        dn42LowerNumber = lib.mkOption { type = lib.types.int; };
        dn42LowerNumberString = lib.mkOption {
          type = lib.types.str;
          default = padDn42LowerNumber asCfg.dn42LowerNumber;
          readOnly = true;
        };
        number = lib.mkOption {
          type = lib.types.int;
          default = asCfg.dn42HigherNumber + asCfg.dn42LowerNumber;
        };
        cidrV4 = lib.mkOption { type = lib.types.str; };
        cidrV6 = lib.mkOption { type = lib.types.str; };
        parsedCidrV4 = lib.mkOption {
          type = lib.types.submodule selfLib.cidr.module;
          default = selfLib.cidr.parse asCfg.cidrV4;
        };
        parsedCidrV6 = lib.mkOption {
          type = lib.types.submodule selfLib.cidr.module;
          default = selfLib.cidr.parse asCfg.cidrV6;
        };
        me = lib.mkOption {
          type = lib.types.str;
          default = config.networking.hostName;
        };
        hosts = lib.mkOption {
          type = with lib.types; attrsOf (submodule peerHostOptions);
          default = { };
        };
        peerHosts = lib.mkOption {
          type = with lib.types; attrsOf (submodule peerHostOptions);
          default = lib.filterAttrs (key: _: key != asCfg.me) asCfg.hosts;
          readOnly = true;
        };
        thisHost = lib.mkOption { type = lib.types.submodule thisHostOptions; };
      };
      dns = {
        enable = lib.mkEnableOption "dn42 dns";
        domains = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ "dn42" ];
        };
        nameServers = lib.mkOption {
          type = with lib.types; listOf str;
          default = [
            # a0.recursive-servers.dn42
            "172.20.0.53"
            "fd42:d42:d42:54::1"
            # a3.recursive-servers.dn42
            "172.23.0.53"
            "fd42:d42:d42:53::1"
          ];
        };
      };
      certificateAuthority = {
        trust = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
      };
      firewall = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
        };
      };
    };
  };

  imports = [
    ./_bgp.nix
    ./_dns.nix
    ./_ca.nix
    ./_firewall.nix
  ];
  config = lib.mkIf cfg.enable {
    # basic bird2 configurations
    services.bird = {
      enable = true;
      config = lib.mkOrder 50 ''
        # dn42 common configurations

        define DN42OWNAS = ${toString cfg.autonomousSystem.number};
        define DN42OWNIPv4 = ${cfg.autonomousSystem.thisHost.preferredAddressV4};
        define DN42OWNIPv6 = ${cfg.autonomousSystem.thisHost.preferredAddressV6};
        define DN42OWNNETv4 = ${cfg.autonomousSystem.cidrV4};
        define DN42OWNNETv6 = ${cfg.autonomousSystem.cidrV6};
        define DN42OWNNETSETv4 = [${cfg.autonomousSystem.cidrV4}+];
        define DN42OWNNETSETv6 = [${cfg.autonomousSystem.cidrV6}+];

        router id ${cfg.bird.routerId};
      '';
    };

    # dummy interface
    systemd.network.netdevs = {
      "70-${cfg.interfaces.dummy.name}" = {
        netdevConfig = {
          Name = cfg.interfaces.dummy.name;
          Kind = "dummy";
        };
      };
    };
    systemd.network.networks = {
      "70-${cfg.interfaces.dummy.name}" = {
        matchConfig = {
          Name = cfg.interfaces.dummy.name;
        };
        addresses =
          lib.lists.map (a: {
            Address = "${a}/32";
            Scope = "global";
          }) asCfg.thisHost.addressesV4
          ++ lib.lists.map (a: {
            Address = "${a}/128";
            Scope = "global";
          }) asCfg.thisHost.addressesV6;
      };
    };

    # other configurations
    passthru.dn42SupportedTunnelTypes = supportedTunnelTypes;
  };
}
