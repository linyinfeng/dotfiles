{ config, ... }:
{
  home-manager.sharedModules = [
    ({ lib, ... }: {
      home.env.dconf = lib.mkDefault config.programs.dconf.enable;
    })
  ];
}
