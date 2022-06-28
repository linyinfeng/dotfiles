{ self, lib, ... }:

{
  home.stateVersion = lib.mkDefault self.lib.flakeStateVersion;
}
