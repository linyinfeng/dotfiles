{ lib, ... }:
{
  world.profiles.nix.gc.enable = lib.mkDefault true;
  world.profiles.nix.settings.enable = lib.mkDefault true;
  world.profiles.nix.cache.enable = lib.mkDefault true;
  world.profiles.nix.version.enable = lib.mkDefault true;
  world.profiles.nix.access-tokens.enable = lib.mkDefault true;
}
