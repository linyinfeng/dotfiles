{
  config,
  pkgs,
  lib,
  ...
}:
let
  interfaceName = "wg-home";
  inherit (config.networking) hostName;
  port = config.ports.wireguard;
  hosts = {
    owl = {
      ip = "192.168.2.2";
      inherit port;
    };
    xps8930 = {
      ip = "192.168.2.3";
      inherit port;
    };
    enchilada = {
      ip = "192.168.2.101";
      inherit port;
    };
  };
  home = {
    AllowedIPs = [
      "192.168.0.0/24"
      "192.168.1.0/24"
      "192.168.2.0/24"
    ];
    Endpoint = "home.li7g.com:13231";
    PublicKey = "2JEjZzJGtd6Om0JN4RooJ68QtYm1WMZRP+qSgv6lBXE=";
    PersistentKeepalive = 30;
  };
in
{
  systemd.network.netdevs."80-wg-home" = {
    netdevConfig = {
      Name = interfaceName;
      Kind = "wireguard";
    };
    wireguardConfig = {
      PrivateKeyFile = config.sops.secrets."wireguard_private_key".path;
      ListenPort = hosts.${hostName}.port;
    };
    wireguardPeers = [ home ];
  };
  systemd.network.networks."80-wg-home" = {
    matchConfig = {
      Name = interfaceName;
    };
    addresses = [
      {
        Address = "${hosts.${hostName}.ip}/24";
        Scope = "link";
      }
    ];
    routes = lib.lists.map (ip: {
      Destination = ip;
      Scope = "site";
      PreferredSource = hosts.${hostName}.ip;
    }) home.AllowedIPs;
  };
  sops.secrets."wireguard_private_key" = {
    terraformOutput = {
      enable = true;
      perHost = true;
    };
    owner = "systemd-network";
    reloadUnits = [ "systemd-networkd.service" ];
  };
  environment.systemPackages = with pkgs; [ wireguard-tools ];
  networking.firewall.allowedUDPPorts = [ hosts.${hostName}.port ];
  networking.networkmanager.unmanaged = [ interfaceName ];
}
