{ config, lib, ... }:
{
  nix.gc = {
    automatic = true;
    options = lib.mkDefault (
      if config.system.types == [ "server" ] then "--delete-old" else "--delete-older-than 2d"
    );
  };
  nix.settings.min-free = 1024 * 1024 * 1024; # bytes
}
