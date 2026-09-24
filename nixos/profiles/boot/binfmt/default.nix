{
  config,
  lib,
  pkgs,
  ...
}:
{
  boot.binfmt = {
    preferStaticEmulators = true;
    emulatedSystems =
      lib.remove pkgs.stdenv.hostPlatform.system
        (lib.filter (system: (lib.systems.elaborate system).isLinux) config.lib.self.systems);
  };
}
