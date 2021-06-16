{ pkgs, lib, ... }:

{
  services.clean-gcroots.enable = true;
  nix.gc = {
    automatic = true;
    options = lib.mkDefault ''
      --delete-older-than 14d
    '';
  };
}
