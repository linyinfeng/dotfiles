{
  config,
  lib,
  ...
}:
lib.mkMerge [
  {
    networking.networkmanager = {
      enable = true;
      enableStrongSwan = true;
      logLevel = "INFO";
      connectionConfig = {
        "connection.mdns" = 2;
      };
    };

    environment.global-persistence.directories = [
      "/etc/NetworkManager/system-connections"
    ];
  }
  (lib.mkIf config.system.is-vm {
    networking.networkmanager.enable = lib.mkForce false;
  })
]
