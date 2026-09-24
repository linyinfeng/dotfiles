{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  services.vscode-server.enable = true;

  home.global-persistence.directories = [
    ".vscode-server"
  ];
}
