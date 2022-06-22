{ lib, nixosConfig, ... }:

{
  home.stateVersion = lib.mkDefault nixosConfig.system.stateVersion;
}
