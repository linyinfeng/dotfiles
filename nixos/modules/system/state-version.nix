{
  config,
  lib,
  ...
}: {
  system.stateVersion = config.lib.self.flakeStateVersion;
}
