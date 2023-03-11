{
  config,
  lib,
  ...
}: {
  home.stateVersion = config.lib.self.flakeStateVersion;
}
