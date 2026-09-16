{ config, lib, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    sharedModules = [
      ({ lib, ... }: {
        home.stateVersion = lib.mkDefault config.system.stateVersion;
      })
    ];
  };
}
