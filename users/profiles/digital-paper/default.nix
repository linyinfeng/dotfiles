{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nur.repos.linyinfeng.dpt-rp1-py
    nur.repos.linyinfeng.activate-dpt
    (pkgs.stdenv.mkDerivation {
      name = "digital-paper-scripts";
      src = ./scripts;
      installPhase = ''
        mkdir -p $out/bin
        cp -R $src/* $out/bin
      '';
    })
  ];
}
