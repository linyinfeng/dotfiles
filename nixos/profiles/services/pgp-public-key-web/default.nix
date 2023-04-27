{pkgs, ...}: let
  root = pkgs.runCommand "pgp-public-key-root" {preferLocalBuild = true;} ''
    mkdir -p $out
    cp "${./index.html}" $out/index.html
    cp "${../../users/yinfeng/_pgp/pub.asc}" $out/pub.asc
  '';
in {
  services.nginx.virtualHosts."pgp-public-key.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/".root = root;
  };
}
