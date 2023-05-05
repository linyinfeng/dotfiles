{
  config,
  pkgs,
  lib,
  ...
}: let
  interfaceName = "dn42mesh";
  hostName = config.networking.hostName;
  port = config.ports.wireguard-dn42-self;
  allHosts = config.lib.self.data.hosts;
  enabledHosts = lib.filterAttrs (_name: hostData: hostData.dn42_host_indices != []) allHosts;
  enabled = enabledHosts ? ${hostName};
  thisHostData = enabledHosts.hostName;
  mkIps = hostData: hostData.dn42_v4_addresses ++ hostData.dn42_v6_addresses;
  ips = mkIps thisHostData;
  otherHosts = lib.filterAttrs (name: _: name != hostName) enabledHosts;
  peers =
    lib.mapAttrsToList (name: hostData: {
      endpoint = "${name}.li7g.com";
      publicKey = hostData.wireguard_public_key;
      allowedIps = mkIps hostData;
      persistentKeepalive = 30;
      dynamicEndpointRefreshSeconds = 60;
    })
    otherHosts;
  connections = lib.mapAttrs' (peerName: hostData:
    lib.nameValuePair "mesh-peer-${peerName}" {
      remote_addrs =
        hostData.endpoints_v4
        ++ hostData.endpoints_v6
        ++ [
          "%any" # allow connection from anywhere
        ];
      # sign round authentication
      local.main = {
        auth = "pubkey";
        certs = [config.sops.secrets."ike_cert_pem".path];
        id = "${hostName}.li7g.com";
      };
      remote.main = {
        auth = "pubkey";
        id = "${peerName}.li7g.com";
      };
      children.dn42 = {
        # TODO
        start_action = "none";
      };
    })
  otherHosts;
in
  lib.mkIf enabled {
    services.strongswan-swanctl = {
      enable = true;
      swanctl = {
        inherit connections;
        authorities.main.cacert = "ca.pem";
      };
    };
    environment.etc."swanctl/ecdsa/key.pem".source =
      config.sops.secrets."ike_private_key_pem".path;
    environment.etc."/swanctl/x509ca/ca.pem".text = config.lib.self.data.ca_cert_pem;
    environment.systemPackages = with pkgs; [
      strongswan
    ];
    sops.secrets."ike_cert_pem" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "strongswan-swanctl.service" ];
    };
    sops.secrets."ike_private_key_pem" = {
      sopsFile = config.sops-file.terraform;
      restartUnits = [ "strongswan-swanctl.service" ];
    };
    networking.firewall.allowedUDPPorts = with config.ports; [
      ipsec-ike
      ipsec-nat-traversal
    ];
    networking.firewall.extraCommands = ''
      iptables --append nixos-fw --protocol 50 --jump nixos-fw-accept # IPSec ESP
      iptables --append nixos-fw --protocol 51 --jump nixos-fw-accept # IPSec AH
    '';
  }
