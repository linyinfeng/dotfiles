{ config, lib, ... }:

lib.mkMerge [
  {
    networking.networkmanager = {
      enable = true;
      enableStrongSwan = true;
    };

    environment.etc."ipsec.secrets".text = ''
      include ipsec.d/ipsec.nm-l2tp.secrets
    '';

    environment.global-persistence.directories = [
      "/etc/NetworkManager/system-connections"
    ];
  }
  (lib.mkIf config.system.is-vm-test {
    networking.networkmanager.enable = lib.mkForce false;
  })
]
