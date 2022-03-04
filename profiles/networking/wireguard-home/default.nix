{ config, pkgs, ... }:

let
  hostName = config.networking.hostName;
  hosts = {
    t460p = {
      ip = "192.168.2.2/32";
      publicKey = "1Z1Z+wNd21Uhd1O9ujCdJVqcv40MTkBCpmSfwFoLrkY=";
    };
    xps8930 = {
      ip = "192.168.2.3/32";
      publicKey = "ucLym/N2nVNc2uxEFCTY+KTJhYZ1KSCw35W0C5JGeyE=";
    };
  };
  ip = hosts.${hostName}.ip;
  homeIp = "192.168.2.1/32";
  home = {
    allowedIPs = [ homeIp ];
    endpoint = "home.li7g.com:13231";
    publicKey = "2JEjZzJGtd6Om0JN4RooJ68QtYm1WMZRP+qSgv6lBXE=";
  };
in
{
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ ip ];
      peers = [ home ];
      privateKeyFile = config.sops.secrets."wireguard".path;
    };
  };
  sops.secrets."wireguard".sopsFile = config.sops.secretsDir + /${hostName}.yaml;
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}
