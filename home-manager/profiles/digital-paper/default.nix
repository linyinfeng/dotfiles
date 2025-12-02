{ pkgs, ... }:
{
  home.packages = with pkgs; [
    linyinfeng.dpt-rp1-py
    linyinfeng.activate-dpt
  ];

  home.global-persistence.directories = [ ".dpapp" ];
}
