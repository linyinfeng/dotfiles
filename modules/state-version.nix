{ self, lib, ... }:

{
  system.stateVersion = lib.mkDefault self.lib.flakeStateVersion;
}
