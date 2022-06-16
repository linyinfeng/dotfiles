{ config, pkgs, lib, ... }:

let
  gitRoot = "/srv/git";
in
{
  security.acme.certs."main".extraDomainNames = [
    "git.li7g.com"
  ];

  services.gitweb = {
    projectroot = gitRoot;
    gitwebTheme = true;
    extraConfig = ''
      $feature{'highlight'}{'default'} = [1];
      $feature{'ctags'}{'default'} = [1];
      $feature{'avatar'}{'default'} = ['gravatar'];
    '';
  };

  services.nginx.gitweb = {
    enable = true;
    virtualHost = "git.li7g.com";
    location = "/gitweb";
  };
  services.nginx.virtualHosts."git.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";
  };

  environment.global-persistence.directories = [
    gitRoot
  ];
}
