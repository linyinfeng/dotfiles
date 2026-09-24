{ config, ... }:
{
  home-manager.sharedModules = [
    ({ lib, ... }: {
      home.env = {
        dconf = lib.mkDefault config.programs.dconf.enable;
        types = lib.mkDefault config.system.types;
        systemdPackage = lib.mkDefault config.systemd.package;
        hostName = lib.mkDefault config.networking.hostName;
        hosts = lib.mkDefault (lib.attrNames config.networking.hostsData.indexedHosts);
        sshPort = lib.mkDefault config.ports.ssh;
        inputMethod = lib.mkDefault config.i18n.inputMethod.type;
      };
    })
  ];
}
