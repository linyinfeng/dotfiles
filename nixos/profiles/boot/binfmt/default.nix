{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt.emulatedSystems = lib.remove (pkgs.stdenv.hostPlatform.system) config.lib.self.systems;
}
