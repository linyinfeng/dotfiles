{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.networking.mesh;

  xfrmIfId = hostCfg: hostCfg.ipsec.xfrmInterfaceId;
  xfrmIfIdString = hostCfg: toString (xfrmIfId hostCfg);
  xfrmIfName = name: hostCfg: "${cfg.interfaces.namePrefix}-i${name}";

  hostPrefixLength = family:
    if family == "ipv4"
    then 32
    else if family == "ipv6"
    then 128
    else throw "unreachable";
  hostPrefixLengthString = family: toString (hostPrefixLength family);

  mkStaticRoutes = cidrs:
    lib.flatten (lib.mapAttrsToList (name: cidrCfg:
      lib.lists.map
      (a: "route ${a.address}/${hostPrefixLengthString cidrCfg.family} ${a.routeConfig};")
      cfg.thisHost.cidrs.${name}.addresses)
    cidrs);

  cidrOptions = {name, ...}: {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
      family = lib.mkOption {
        type = lib.types.enum ["ipv4" "ipv6"];
      };
      prefix = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
      };
    };
  };

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
      ipsec = {
        initiate = lib.mkOption {
          type = lib.types.enum ["ipv4" "ipv6"];
          default = "ipv6";
        };
        xfrmInterfaceId = lib.mkOption {
          type = lib.types.int;
        };
      };
      connection = {
        endpointsV4 = lib.mkOption {
          type = with lib.types; listOf str;
        };
        endpointsV6 = lib.mkOption {
          type = with lib.types; listOf str;
        };
      };
      cidrs = lib.mkOption {
        type = with lib.types; attrsOf (submodule hostCidrOptions);
        default = {};
      };
    };
  };

  hostCidrOptions = {
    config,
    name,
    ...
  }: {
    options = {
      cidr = lib.mkOption {
        type = lib.types.str;
        default = name;
      };
      addresses = lib.mkOption {
        type = with lib.types; listOf (submodule addressOptions);
      };
      preferredAddress = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  addressOptions = {
    options = {
      address = lib.mkOption {
        type = lib.types.str;
      };
      routeConfig = lib.mkOption {
        type = lib.types.str;
      };
      assign = lib.mkOption {
        type = lib.types.bool;
      };
    };
  };

  babelInterfaceOptions = {
    options = {
      type = lib.mkOption {
        type = lib.types.enum ["wired" "wireless" "tunnel"];
      };
      extraConfig = lib.mkOption {
        type = lib.types.lines;
      };
    };
  };
in {
  options = {
    networking.mesh = {
      enable = lib.mkEnableOption "mesh";
      me = lib.mkOption {
        type = lib.types.str;
        default = config.networking.hostName;
      };
      interfaces = {
        dummy.name = lib.mkOption {
          type = lib.types.str;
          default = "mesh";
        };
        namePrefix = lib.mkOption {
          type = lib.types.str;
          default = "mesh";
        };
        mtu = lib.mkOption {
          type = lib.types.int;
          default = 1280;
        };
      };
      cidrs = lib.mkOption {
        type = with lib.types; attrsOf (submodule cidrOptions);
        default = {};
      };
      cidrsV4 = lib.mkOption {
        type = with lib.types; attrsOf (submodule cidrOptions);
        default = lib.filterAttrs (_: c: c.family == "ipv4") cfg.cidrs;
        readOnly = true;
      };
      cidrsV6 = lib.mkOption {
        type = with lib.types; attrsOf (submodule cidrOptions);
        default = lib.filterAttrs (_: c: c.family == "ipv6") cfg.cidrs;
        readOnly = true;
      };
      bird.babelInterfaceConfig = lib.mkOption {
        type = lib.types.lines;
      };
      routingTable = {
        id = lib.mkOption {
          type = lib.types.int;
          default = 200;
        };
        name = lib.mkOption {
          type = lib.types.str;
          default = "mesh";
        };
        priority = lib.mkOption {
          type = lib.types.int;
        };
      };
      hosts = lib.mkOption {
        type = with lib.types; attrsOf (submodule hostOptions);
        default = {};
      };
      thisHost = lib.mkOption {
        type = lib.types.submodule hostOptions;
        default = cfg.hosts.${cfg.me};
        readOnly = true;
      };
      peerHosts = lib.mkOption {
        type = with lib.types; attrsOf (submodule hostOptions);
        default = lib.filterAttrs (name: _: name != cfg.me) cfg.hosts;
        readOnly = true;
      };
      extraInterfaces = lib.mkOption {
        type = with lib.types; attrsOf (submodule babelInterfaceOptions);
        default = {};
      };
      ipsec = {
        enable = lib.mkEnableOption "IPSec/IKEv2";
        caCert = lib.mkOption {
          type = lib.types.str;
        };
        caCertFile = lib.mkOption {
          type = lib.types.path;
          default = pkgs.writeText "ipsec_ca_cert.pem" cfg.ipsec.caCert;
        };
        hostCert = lib.mkOption {
          type = lib.types.str;
        };
        hostCertFile = lib.mkOption {
          type = lib.types.path;
          default = pkgs.writeText "ipsec_host_cert.pem" cfg.ipsec.hostCert;
        };
        hostCertKeyFile = lib.mkOption {
          type = lib.types.path;
        };
      };
    };
  };
  config = lib.mkIf (cfg.enable) (lib.mkMerge [
    # network management tools and compatibility issues
    {
      systemd.network.enable = true;
      boot.kernel.sysctl = {
        "net.ipv6.conf.default.forwarding" = 1;
        "net.ipv4.conf.default.forwarding" = 1;
        "net.ipv6.conf.all.forwarding" = 1;
        "net.ipv4.conf.all.forwarding" = 1;
        # disable rp_filter
        "net.ipv4.conf.all.rp_filter" = 0;
        "net.ipv4.conf.default.rp_filter" = 0;
        "net.ipv4.conf.*.rp_filter" = 0;
      };
      networking.firewall.checkReversePath = false;
      networking.networkmanager.unmanaged = [
        cfg.interfaces.dummy.name
      ];
      services.strongswan-swanctl.strongswan.extraConfig = lib.mkIf config.networking.fw-proxy.tproxy.enable ''
        charon {
          # tproxy's routing table routes everything to lo
          ignore_routing_tables = ${toString config.networking.fw-proxy.tproxy.routingTable}
        }
      '';
    }

    # bird and device protocol
    {
      services.bird2 = {
        enable = true;
        config = lib.mkOrder 50 ''
          protocol device device_main { }
        '';
      };
    }

    # dummy device
    {
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
        };
      };
    }

    # routing table
    {
      systemd.network.config.routeTables = {
        ${cfg.routingTable.name} = cfg.routingTable.id;
      };
      systemd.network.networks = {
        "70-${cfg.interfaces.dummy.name}" = {
          routingPolicyRules = [
            {
              routingPolicyRuleConfig = {
                Family = "both";
                Table = cfg.routingTable.id;
                Priority = cfg.routingTable.priority;
              };
            }
          ];
        };
      };
    }

    # address of the dummy interface
    {
      systemd.network.networks = {
        "70-${cfg.interfaces.dummy.name}" = {
          address = lib.flatten (lib.mapAttrsToList (_: hostCidrCfg: let
            inherit (cfg.cidrs.${hostCidrCfg.cidr}) family;
          in
            lib.lists.map (a: "${a.address}/${hostPrefixLengthString family}")
            (lib.filter (a: a.assign) hostCidrCfg.addresses))
          cfg.thisHost.cidrs);
        };
      };
    }

    # bird
    {
      services.bird2.config = lib.mkOrder 100 ''
        # babel configurations

        ipv4 table mesh_v4 { }
        ipv6 table mesh_v6 { }

        protocol static static_mesh_v4 {
          ${lib.concatStringsSep "\n  " (mkStaticRoutes cfg.cidrsV4)}
          ipv4 {
            table mesh_v4;
            import all;
            export none;
          };
        }
        protocol static static_mesh_v6 {
          ${lib.concatStringsSep "\n  " (mkStaticRoutes cfg.cidrsV6)}
          ipv6 {
            table mesh_v6;
            import all;
            export none;
          };
        }
        filter filter_mesh_kernel_v4 {
          if source = RTS_STATIC then reject;
          ${lib.concatMapStringsSep "\n  " (cidr: "if net ~ [ ${cidr.prefix}+ ] then krt_prefsrc = ${cfg.thisHost.cidrs.${cidr.name}.preferredAddress};")
          (lib.attrValues cfg.cidrsV4)}
          accept;
        }
        filter filter_mesh_kernel_v6 {
          if source = RTS_STATIC then reject;
          ${lib.concatMapStringsSep "\n  " (cidr: "if net ~ [ ${cidr.prefix}+ ] then krt_prefsrc = ${cfg.thisHost.cidrs.${cidr.name}.preferredAddress};")
          (lib.attrValues cfg.cidrsV6)}
          accept;
        }
        protocol kernel kernel_mesh_v4 {
          kernel table ${toString cfg.routingTable.id};
          ipv4 {
            table mesh_v4;
            export filter filter_mesh_kernel_v4;
            import none;
          };
        }
        protocol kernel kernel_mesh_v6 {
          kernel table ${toString cfg.routingTable.id};
          ipv6 {
            table mesh_v6;
            export filter filter_mesh_kernel_v6;
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
          interface "${cfg.interfaces.namePrefix}-*" {
            type tunnel;
            ${cfg.bird.babelInterfaceConfig}
          };
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (pattern: ifCfg: ''
            interface "${pattern}" {
              type ${ifCfg.type};
              ${ifCfg.extraConfig}
            };
          '')
          cfg.extraInterfaces)}
        }
      '';
      networking.firewall.allowedUDPPorts = [
        config.ports.babel
      ];
    }

    # IPSec/IKEv2 mesh
    (lib.mkIf cfg.ipsec.enable {
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
                    if cfg.thisHost.ipsec.initiate == "ipv6"
                    then hostCfg.connection.endpointsV6 ++ hostCfg.connection.endpointsV4
                    else if cfg.thisHost.ipsec.initiate == "ipv4"
                    then hostCfg.connection.endpointsV4 ++ hostCfg.connection.endpointsV6
                    else []
                  )
                  ++ [
                    "%any" # allow connection from anywhere
                  ];
                # sign round authentication
                local.main = {
                  auth = "pubkey";
                  certs = ["${cfg.ipsec.hostCertFile}"];
                  id = "${cfg.thisHost.name}.li7g.com";
                };
                remote.main = {
                  auth = "pubkey";
                  id = "${peerName}.li7g.com";
                };
                children.mesh = {
                  start_action = "trap";
                  # trap traffic using XFRM interface id
                  if_id_in = xfrmIfIdString hostCfg;
                  if_id_out = xfrmIfIdString hostCfg;
                  local_ts = ["0.0.0.0/0" "::/0"];
                  remote_ts = ["0.0.0.0/0" "::/0"];
                };
              };
          in
            lib.mapAttrs' mkConnection cfg.peerHosts;
          authorities.main.cacert = "ca.pem";
        };
      };
      environment.etc."swanctl/ecdsa/key.pem".source = cfg.ipsec.hostCertKeyFile;
      environment.etc."/swanctl/x509ca/ca.pem".source = cfg.ipsec.caCertFile;

      # mesh interfaces
      systemd.network.netdevs =
        lib.mapAttrs' (
          peerName: hostCfg:
            lib.nameValuePair
            "70-${xfrmIfName peerName hostCfg}"
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
        cfg.peerHosts;
      systemd.network.networks =
        lib.mapAttrs' (
          peerName: hostCfg:
            lib.nameValuePair
            "70-${xfrmIfName peerName hostCfg}"
            {
              matchConfig = {
                Name = xfrmIfName peerName hostCfg;
              };
              linkConfig = {
                Multicast = true;
                MTUBytes = toString cfg.interfaces.mtu;
              };
            }
        )
        cfg.peerHosts;

      # management tools
      environment.systemPackages = with pkgs; [
        strongswan
      ];

      # firewall settings
      networking.firewall = lib.mkMerge [
        {
          allowedUDPPorts = with config.ports; [
            ipsec-ike
            ipsec-nat-traversal
          ];
        }
        (
          if config.networking.nftables.enable
          then {
            extraInputRules = ''
              meta l4proto esp counter accept
              meta l4proto ah  counter accept
            '';
          }
          else {
            extraCommands = ''
              ip46tables --append nixos-fw --protocol 50 --jump nixos-fw-accept # IPSec ESP
              ip46tables --append nixos-fw --protocol 51 --jump nixos-fw-accept # IPSec AH
            '';
          }
        )
      ];
    })
  ]);
}