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
      };
    })
  ];
}
