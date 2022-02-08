{ config, pkgs, ... }:

let
  hostName = config.networking.hostName;
  hosts = {
    t460p = {
      ip = "192.168.3.2/24";
      pubKey = "1Z1Z+wNd21Uhd1O9ujCdJVqcv40MTkBCpmSfwFoLrkY=";
    };
  };
  ip = hosts.${hostName}.ip;
  homeIp = "192.168.3.1/32";
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
      privateKeyFile = config.sops.secrets."wireguard/${hostName}".path;
    };
  };
  sops.secrets."wireguard/${hostName}" = { };
  environment.systemPackages = with pkgs; [
    wireguard-tools
  ];
}
