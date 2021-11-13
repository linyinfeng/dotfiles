{ config, pkgs, lib, ... }:

let
  secretConfig = file: {
    inherit file;
    mode = "440";
    group = config.users.groups.wheel.name;
  };
in
{
  environment.systemPackages = [
    (pkgs.stdenvNoCC.mkDerivation {
      name = "campus-network-scripts";
      buildCommand = ''
        install -Dm755 $campusNetLogin  $out/bin/campus-net-login
        install -Dm755 $campusNetLogout $out/bin/campus-net-logout
      '';
      campusNetLogin = pkgs.substituteAll {
        src = ./scripts/login.sh;
        isExecutable = true;
        inherit (pkgs.stdenvNoCC) shell;
        inherit (pkgs) curl;
        usernameFile = config.sops.secrets."campus-net/username".path;
        passwordFile = config.sops.secrets."campus-net/password".path;
      };
      campusNetLogout = pkgs.substituteAll {
        src = ./scripts/logout.sh;
        isExecutable = true;
        inherit (pkgs.stdenvNoCC) shell;
        inherit (pkgs) curl;
      };
    })
  ];
  sops.secrets = {
    "campus-net/username" = { };
    "campus-net/password" = { };
  };
  nix.binaryCaches = lib.mkOrder 500 [ "https://mirrors.nju.edu.cn/nix-channels/store" ];
}
