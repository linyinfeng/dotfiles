{
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    networking.networkmanager = {
      enable = true;
      # TODO broken
      enableStrongSwan = false;
      logLevel = "INFO";
      firewallBackend = "nftables";
      connectionConfig = {
        "connection.mdns" = 2;
      };
    };

    environment.etc."ipsec.secrets".text = ''
      include ipsec.d/ipsec.nm-l2tp.secrets
    '';

    environment.global-persistence.directories = [
      "/etc/NetworkManager/system-connections"
    ];
  }
  (lib.mkIf config.system.is-vm {
    networking.networkmanager.enable = lib.mkForce false;
  })
]
