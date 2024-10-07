{ pkgs, lib, ... }:
let
  inherit (pkgs) ardour;
  majorVersion = lib.versions.major ardour.version;
in
{
  home.packages = with pkgs; [ ardour ];
  home.global-persistence.directories = [ ".config/ardour${toString majorVersion}" ];
}
