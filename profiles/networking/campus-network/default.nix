{ config, pkgs, ... }:

let
  secretConfig = file: {
    inherit file;
    mode = "440";
    group = config.users.groups.wheel.name;
  };
in
{
  age.secrets = {
    campus-net-username = secretConfig ../../../secrets/campus-net-username.age;
    campus-net-password = secretConfig ../../../secrets/campus-net-password.age;
  };
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
        usernameFile = config.age.secrets.campus-net-username.path;
        passwordFile = config.age.secrets.campus-net-password.path;
      };
      campusNetLogout = pkgs.substituteAll {
        src = ./scripts/logout.sh;
        isExecutable = true;
        inherit (pkgs.stdenvNoCC) shell;
        inherit (pkgs) curl;
      };
    })
  ];
}
