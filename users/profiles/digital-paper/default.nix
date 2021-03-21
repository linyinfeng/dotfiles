{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nur.repos.linyinfeng.dpt-rp1-py
    nur.repos.linyinfeng.activate-dpt
  ];
}
