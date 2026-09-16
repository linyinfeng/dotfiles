{ config, ... }:
{
  home-manager.sharedModules = [
    ({ lib, ... }: {
      home.env = {
        dconf = lib.mkDefault config.programs.dconf.enable;
        types = lib.mkDefault config.system.types;
        desktopManagers = lib.mkDefault (
          lib.optionals config.services.desktopManager.gnome.enable [ "gnome" ]
        );
        systemdPackage = lib.mkDefault config.systemd.package;
        hostName = lib.mkDefault config.networking.hostName;
        hosts = lib.mkDefault (lib.attrNames config.networking.hostsData.indexedHosts);
        sshPort = lib.mkDefault config.ports.ssh;
        inputMethod = lib.mkIf (config.i18n.inputMethod.type != null) (
          lib.mkDefault config.i18n.inputMethod.type
        );
      };
    })
  ];
}
