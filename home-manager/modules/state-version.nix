{
  config,
  lib,
  ...
}: {
  home.stateVersion = lib.mkDefault config.lib.self.flakeStateVersion;
}
