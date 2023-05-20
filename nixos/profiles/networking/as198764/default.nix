{
  config,
  lib,
  ...
}: let
  anycastIp = "2a0c:b641:a11:badd::1:1/128";
  tunnelPeerIp = "2a0c:b641:a11:badd::ffff/128";
  # https://quickest-canoe-05c.notion.site/AS198764-f766b0a688f44863b1d5b78992b69e79
  configTable = {
    # 美西
    hil0 = {
      endpoint = "[2602:fe69:455::1]:51820";
      publicKey = "jW2/wl2Op0YfkrlytqI29LGoB5V6Lk6pud/bD5Myjm8=";
      local = "2a0c:b641:a11:badd::1/128";
    };
    # 欧洲
    fsn0 = {
      endpoint = "[2a0c:b640:10::205]:51820";
      publicKey = "RddjU8oihMKuQwSIDvPQ5MYNyKGJJfmZBJsaAb/b0WA=";
      local = "2a0c:b641:a11:badd::2/128";
    };
    # 美东
    mtl0 = {
      endpoint = "198.98.51.31:51820";
      publicKey = "E7prrcg0x+N2j7C3A0GMA1gAYeASw5G37EXRx+JlUwU=";
      local = "2a0c:b641:a11:badd::3/128";
    };
    # 亚太
    hkg0 = {
      endpoint = "[2401:c080:3800:29ee:5400:4ff:fe68:caed]:51820";
      publicKey = "98tLXb155tbbrxF/zzmcZZ0zExJM6GSSZEeFoypbvHk=";
      local = "2a0c:b641:a11:badd::6/128";
    };
  };
  hostName = config.networking.hostName;
  cfg = configTable.${hostName};
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
  systemd.network.networks.as198764 = {
    matchConfig = {
      Name = "as198764";
    };
    addresses = [
      {
        addressConfig = {
          Address = cfg.local;
          Peer = tunnelPeerIp;
          Scope = "global";
        };
      }
      {
        addressConfig = {
          Address = anycastIp;
          Scope = "global";
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
      route ${cfg.local} reject;
      ipv6 {
        table mesh_v6;
        import all;
        export none;
      };
    }
  '');
}
