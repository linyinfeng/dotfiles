{ pkgs, ... }:
{
  home.packages = with pkgs; [
    blender
  ];
  home.global-persistence.directories = [ ".config/blender" ];
}
