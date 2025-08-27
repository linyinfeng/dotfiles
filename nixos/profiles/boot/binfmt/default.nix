{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt = {
    # preferStaticEmulators = true; # TODO broken
    emulatedSystems = lib.remove pkgs.stdenv.hostPlatform.system config.lib.self.systems;
  };
}
