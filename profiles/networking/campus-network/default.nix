{ config, pkgs, ... }:

let
  secretConfig = {
    mode = "440";
    group = config.users.groups.keys.name;
  };
in
{
  sops.secrets = {
    campus-net-username = secretConfig;
    campus-net-password = secretConfig;
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
        usernameFile = config.sops.secrets.campus-net-username.path;
        passwordFile = config.sops.secrets.campus-net-password.path;
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
