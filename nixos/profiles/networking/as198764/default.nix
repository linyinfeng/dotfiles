{
  config,
  lib,
  ...
}: let
  inherit (config.lib.self) data;
  cidr = data.as198764_v6_cidr;
  anycastIp = "2a0c:b641:a11:badd::1:1";
  tunnelPeerIp = "2a0c:b641:a11:badd::ffff";
  # https://quickest-canoe-05c.notion.site/AS198764-f766b0a688f44863b1d5b78992b69e79
  configTable = {
    # 美西
    hil0 = {
      endpoint = "[2602:fe69:455:524:badd::1]:20003";
      publicKey = "Dpj0VOIdqeymB+C/f1pTqRNDkn6SARIELY4XQ1m+g1E=";
    };
    # 欧洲
    fsn0 = {
      endpoint = "[2a0c:b640:10::205]:20003";
      publicKey = "RddjU8oihMKuQwSIDvPQ5MYNyKGJJfmZBJsaAb/b0WA=";
    };
    # 美东
    mtl0 = {
      endpoint = "198.98.51.31:20003";
      publicKey = "E7prrcg0x+N2j7C3A0GMA1gAYeASw5G37EXRx+JlUwU=";
    };
    # 亚太
    hkg0 = {
      endpoint = "[2401:c080:3800:29ee:5400:4ff:fe68:caed]:20003";
      publicKey = "98tLXb155tbbrxF/zzmcZZ0zExJM6GSSZEeFoypbvHk=";
    };
  };
  hostName = config.networking.hostName;
  cfg = configTable.${hostName};
  hostData = data.hosts.${hostName};
in {
  systemd.network.netdevs.as198764 = {
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
          Endpoint = "${cfg.endpoint}";
          PublicKey = cfg.publicKey;
          AllowedIPs = ["::/0" "0.0.0.0/0"];
          PersistentKeepalive = 30;
        };
      }
    ];
  };
  systemd.network.config.routeTables = {
    as198764 = config.routingTables.as198764;
  };
  systemd.network.networks.as198764 = {
    matchConfig = {
      Name = "as198764";
    };
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
      hostData.as198764_addresses_v6
      ++ [
        {
          addressConfig = {
            Address = "${anycastIp}/128";
            Scope = "global";
          };
        }
      ];
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
    ];
  };
  sops.secrets."wireguard_private_key" = {
    sopsFile = config.sops-file.terraform;
    group = "systemd-network";
    mode = "440";
    restartUnits = ["systemd-networkd.service"];
  };
  services.bird2.config = lib.mkIf (config.networking.dn42.enable) (lib.mkOrder 120 ''
    protocol static static_as198764 {
      ${lib.concatMapStringsSep "  \n" (a: "route ${a}/128 reject;") hostData.as198764_addresses_v6}
      ipv6 {
        table mesh_v6;
        import all;
        export none;
      };
    }
  '');
}
