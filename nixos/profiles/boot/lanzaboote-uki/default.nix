{ pkgs, lib, ... }:
let
  splash = pkgs.runCommand "splash.bmp" { nativeBuildInputs = with pkgs; [ imagemagick ]; } ''
    convert \
      -verbose \
      -background black \
      -resize 256x256 \
      ${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg \
      $out
  '';
  ini = pkgs.formats.ini { };
  ukifyConfig = ini.generate "ukify-config" {
    UKI = {
      Splash = splash;
    };
  };
  extraUkifyArgs = [
    "--config"
    ukifyConfig
  ];
in
{
  boot.lanzaboote = {
    mode = "uki";
    extraArgs = lib.lists.map (a: "--extra-ukify-args=${a}") extraUkifyArgs;
  };
  passthru = {
    inherit ukifyConfig;
  };
}
