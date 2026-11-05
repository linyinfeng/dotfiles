{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  # Off: patchelf 0.19.2 corrupts the node it patches (NixOS/patchelf#674), which
  # makes every server install fail with "(code 139)". Unpatched only needs nix-ld,
  # which nixos/suites/development.nix enables.
  # TODO: re-enable once patchelf >= 0.19.3 (NixOS/nixpkgs#582116) or
  # nixos-vscode-server#105 lands.
  # services.vscode-server.enable = true;

  assertions = [
    {
      assertion = lib.versionOlder pkgs.patchelf.version "0.19.3";
      message = ''
        patchelf ${pkgs.patchelf.version} no longer needs the vscode-server
        workaround: re-enable services.vscode-server and drop this assertion.
      '';
    }
  ];

  home.global-persistence.directories = [
    ".vscode-server"
  ];
}
