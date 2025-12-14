{ ... }:
{
  nix.gc.automatic = true;
  nix.settings.min-free = 1024 * 1024 * 1024; # bytes
}
