{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    nix-alien
  ];
}
