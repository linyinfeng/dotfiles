{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [ ];
    };
  };

  home.global-persistence.directories = [
    ".vscode"

    ".config/Code"
  ];
}
