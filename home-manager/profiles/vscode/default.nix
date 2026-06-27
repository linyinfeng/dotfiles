{ pkgs, ... }:
{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [ ];
    };
  };

  programs.git.ignores = [
    "/.vscode"
  ];

  home.global-persistence.directories = [
    ".vscode"
    ".vscode-shared"

    ".config/Code"
  ];
}
