{
  config,
  pkgs,
  lib,
  ...
}:
let
  interfaceName = "wg-home";
  inherit (config.lib.self) cidr data;
  subnet = data.subnets.wireguard-home;
  inherit (cidr.parse subnet.cidr) prefixLength;
  address = subnet.${config.networking.hostName};
  port = config.ports.wireguard;
  home = {
    AllowedIPs = [ subnet.cidr ];
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
      ListenPort = port;
    };
    wireguardPeers = [ home ];
  };
  systemd.network.networks."80-wg-home" = {
    matchConfig = {
      Name = interfaceName;
    };
    linkConfig.RequiredForOnline = false;
    addresses = [
      {
        Address = "${address}/${toString prefixLength}";
        Scope = "link";
      }
    ];
    routes = lib.lists.map (ip: {
      Destination = ip;
      Scope = "site";
      PreferredSource = address;
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
  networking.firewall.allowedUDPPorts = [ port ];
  networking.networkmanager.unmanaged = [ interfaceName ];
  topology.self.interfaces.${interfaceName} = {
    virtual = true;
    renderer.hidePhysicalConnections = config.topology.tidy;
    physicalConnections = [
      (config.lib.topology.mkConnection "home-router" "wireguard1")
    ];
  };
}
