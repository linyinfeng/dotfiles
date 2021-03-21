{ pkgs, ... }:

let
  copyScripts = ''
    mkdir -p $out/bin
    cp -R $src/* $out/bin
  '';

  scripts = pkgs.stdenv.mkDerivation {
    name = "user-shell-scripts";
    src = ./scripts;
    installPhase = copyScripts;
  };

  secretScripts = pkgs.stdenv.mkDerivation
    {
      name = "user-secret-shell-scripts";
      src = ../../../secrets/users/profiles/scripts/secret-scripts;
      installPhase = copyScripts;
    };
in

{
  home.packages = [
    scripts
    secretScripts
  ];
}
