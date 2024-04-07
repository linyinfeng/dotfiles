{ pkgs, ... }:
{
  home.packages = with pkgs; [ cachix ];

  home.global-persistence.directories = [ ".config/cachix" ];
}
