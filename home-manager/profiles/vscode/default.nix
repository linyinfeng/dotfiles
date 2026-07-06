{ pkgs, lib, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [ ];
    };
  };

  programs.desktop-files.favorites = lib.mkOrder 1100 [ "code" ];

  programs.git.ignores = [
    "/.vscode"
  ];

  home.global-persistence.directories = [
    ".vscode"
    ".vscode-shared"

    ".config/Code"
  ];
}
