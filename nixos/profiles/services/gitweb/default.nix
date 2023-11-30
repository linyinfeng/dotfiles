{
  config,
  pkgs,
  lib,
  ...
}: let
  gitRoot = "/srv/git";
in {
  services.gitweb = {
    projectroot = gitRoot;
    gitwebTheme = true;
    extraConfig = ''
      $site_name = "git.li7g.com";
      $feature{'highlight'}{'default'} = [1];
      $feature{'avatar'}{'default'} = ['gravatar'];
    '';
  };

  services.nginx.gitweb = {
    enable = true;
    virtualHost = "git.*";
    location = "/gitweb";
  };
  services.nginx.virtualHosts."git.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
  };

  environment.global-persistence.directories = [
    gitRoot
  ];
}
