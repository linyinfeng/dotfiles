{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [ onedrive ];

  home.global-persistence.directories = [
    ".config/onedrive"

    "OneDrive"
  ];
}
