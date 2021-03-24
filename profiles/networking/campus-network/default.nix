{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.stdenvNoCC.mkDerivation {
      name = "campus-network-scripts";
      buildCommand = ''
        install -Dm755 $campusNetLogin  $out/bin/campus-net-login
        install -Dm755 $campusNetLogout $out/bin/campus-net-logout
      '';
      campusNetLogin = pkgs.substituteAll {
        src = ../../../secrets/networking/campus-network/login.sh;
        isExecutable = true;
        inherit (pkgs.stdenvNoCC) shell;
        inherit (pkgs) curl;
      };
      campusNetLogout = pkgs.substituteAll {
        src = ../../../secrets/networking/campus-network/logout.sh;
        isExecutable = true;
        inherit (pkgs.stdenvNoCC) shell;
        inherit (pkgs) curl;
      };
    })
  ];
}
