{ pkgs, ... }:
{
  home.packages = with pkgs; [ onedrive ];
  programs.onedrive = {
    enable = true;
    settings = {
      # currently nothing
    };
  };

  home.global-persistence.directories = [
    ".config/onedrive"

    "OneDrive"
  ];
}
