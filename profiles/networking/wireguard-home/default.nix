{ config, pkgs, lib, ... }:

let
  hostName = config.networking.hostName;
  port = 51820;
  hosts = {
    t460p = {
      ip = "192.168.2.2/32";
      publicKey = "1Z1Z+wNd21Uhd1O9ujCdJVqcv40MTkBCpmSfwFoLrkY=";
      inherit port;
    };
    xps8930 = {
      ip = "192.168.2.3/32";
      publicKey = "ucLym/N2nVNc2uxEFCTY+KTJhYZ1KSCw35W0C5JGeyE=";
      inherit port;
    };
    tencent = {
      ip = "192.168.2.4/32";
      publicKey = "Q4sBAq/1ZPJnW13vNKgjLIPsyT2RbzExQZUZ8qpfgyY=";
      inherit port;
    };
  };
  home = {
    allowedIPs = [
      "192.168.0.0/24"
      "192.168.1.0/24"
      "192.168.2.0/24"
    ];
    endpoint = "home.li7g.com:13231";
    publicKey = "2JEjZzJGtd6Om0JN4RooJ68QtYm1WMZRP+qSgv6lBXE=";
    persistentKeepalive = 30;
    # dynamicEndpointRefreshSeconds = 60;
  };
in
{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ hosts.${hostName}.ip ];
      listenPort = hosts.${hostName}.port;
      peers = [ home ];
      privateKeyFile = config.sops.secrets."wireguard".path;
    };
  };
  # do not auto start
  systemd.services."wireguard-wg0".wantedBy = lib.mkForce [ ];
  sops.secrets."wireguard".sopsFile = config.sops.secretsDir + /${hostName}.yaml;
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
  networking.firewall.allowedUDPPorts = [
    config.networking.wireguard.interfaces.wg0.listenPort
  ];
}
