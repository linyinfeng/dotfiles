{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt = {
    # TODO wait for https://nixpkgs-tracker.ocfox.me/?pr=402027
    # preferStaticEmulators = true;
    emulatedSystems = lib.remove pkgs.stdenv.hostPlatform.system config.lib.self.systems;
  };
}
