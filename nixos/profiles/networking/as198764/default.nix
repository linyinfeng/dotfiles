{
  config,
  lib,
  ...
}: let
  cfg = config.networking.as198764;
  meshCfg = config.networking.mesh;
  inherit (config.lib.self) data;
  filteredHost = lib.filterAttrs (_: hostData: (lib.length hostData.host_indices != 0)) data.hosts;
  cidr = data.as198764_v6_cidr;
  anycastIp = data.as198764_anycast_address;
  tunnelPeerIp = "2a0c:b641:a11:badd::ffff";
  # https://quickest-canoe-05c.notion.site/AS198764-f766b0a688f44863b1d5b78992b69e79
  exitNodeCfgTable = {
    # 美西
    hil0 = {
      endpoint = "[2602:fe69:455:524:badd::1]:20003";
      publicKey = "Dpj0VOIdqeymB+C/f1pTqRNDkn6SARIELY4XQ1m+g1E=";
    };
    # 欧洲
    fsn0 = {
      endpoint = "[2a0c:b640:10::205]:20003";
      publicKey = "xWklmAad9R1xzG1jro/9citY8i3LOhFSyH6i7PzJyQA=";
    };
    # 美东
    mtl0 = {
      endpoint = "198.98.51.31:20003";
      publicKey = "u6lfZGdpdwcq8qU4PDiQkCYAjbRicWzikeVOAUZdpzg=";
    };
    # 亚太
    hkg0 = {
      endpoint = "[2001:df2:5380:460:abcd:eeee:ffff:2]:20003";
      publicKey = "tBBKIAXevD5JLcx4mQIzsm22KvztWEWX1al1xDuqEE4=";
    };
  };
  hostName = config.networking.hostName;
  exitNodeCfg = exitNodeCfgTable.${hostName};
  hostData = data.hosts.${hostName};
in {
  options.networking.as198764 = {
    exit = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = exitNodeCfgTable ? ${hostName};
    };
    anycast = lib.mkOption {
      type = lib.types.bool;
      readOnly = true;
      default = cfg.exit;
    };
  };
  config = lib.mkIf (meshCfg.enable) (lib.mkMerge [
    {
      networking.mesh = {
        cidrs = {
          as198764V6 = {
            family = "ipv6";
            prefix = cidr;
          };
        };
        hosts =
          lib.mapAttrs (_name: hostData: {
            cidrs.as198764V6 = {
              addresses =
                lib.lists.map (address: {
                  inherit address;
                  assign = true;
                })
                hostData.as198764_addresses_v6
                ++ lib.optional cfg.exit {
                  address = tunnelPeerIp;
                  assign = false;
                }
                ++ lib.optional cfg.anycast {
                  address = anycastIp;
                  assign = true;
                };
              preferredAddress = lib.elemAt hostData.as198764_addresses_v6 0;
            };
          })
          filteredHost;
      };
    }
    # common configurations
    {
      systemd.network.config.routeTables = {
        as198764 = config.routingTables.as198764;
      };
      systemd.network.networks."70-as198764" = {
        matchConfig = {
          Name = "as198764";
        };
        routes = [
          {
            routeConfig = {
              Gateway = tunnelPeerIp;
              Table = config.routingTables.as198764;
            };
          }
        ];
        routingPolicyRules = [
          {
            routingPolicyRuleConfig = {
              Priority = config.routingPolicyPriorities.as198764;
              From = cidr;
              Table = config.routingTables.as198764;
            };
          }
          {
            routingPolicyRuleConfig = {
              To = cidr;
              Type = "unreachable";
              Priority = config.routingPolicyPriorities.as198764-catch;
            };
          }
        ];
      };
    }

    (lib.mkIf cfg.exit {
      systemd.network.netdevs."70-as198764" = {
        netdevConfig = {
          Name = "as198764";
          Kind = "wireguard";
        };
        wireguardConfig = {
          PrivateKeyFile = config.sops.secrets."wireguard_private_key".path;
          ListenPort = config.ports.wireguard-as198764;
        };
        wireguardPeers = [
          {
            wireguardPeerConfig = {
              Endpoint = "${exitNodeCfg.endpoint}";
              PublicKey = exitNodeCfg.publicKey;
              AllowedIPs = ["::/0" "0.0.0.0/0"];
              PersistentKeepalive = 30;
            };
          }
        ];
      };
      systemd.network.networks."70-as198764" = {
        networkConfig = {
          LinkLocalAddressing = "no";
        };
        addresses =
          lib.lists.map (a: {
            addressConfig = {
              Address = "${a}/128";
              Peer = "${tunnelPeerIp}/128";
              Scope = "global";
            };
          })
          hostData.as198764_addresses_v6;
        routingPolicyRules = [
          {
            routingPolicyRuleConfig = {
              To = tunnelPeerIp;
              Table = "main";
              Priority = config.routingPolicyPriorities.as198764-peer;
            };
          }
        ];
      };
      sops.secrets."wireguard_private_key" = {
        sopsFile = config.sops-file.terraform;
        group = "systemd-network";
        mode = "440";
        restartUnits = ["systemd-networkd.service"];
      };
    })

    (lib.mkIf (!cfg.exit) {
      systemd.network.netdevs."70-as198764" = {
        netdevConfig = {
          Name = "as198764";
          Kind = "dummy";
        };
      };
    })
  ]);
}
