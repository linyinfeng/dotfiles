{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt = {
    preferStaticEmulators = true;
    emulatedSystems = lib.remove pkgs.stdenv.hostPlatform.system config.lib.self.systems;
  };
}
