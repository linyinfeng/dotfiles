{
  config,
  lib,
  ...
}: {
  system.stateVersion = lib.mkDefault config.lib.self.flakeStateVersion;
}
