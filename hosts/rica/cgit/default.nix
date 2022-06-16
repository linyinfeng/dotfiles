{ config, pkgs, lib, ... }:

let
  gitRoot = "/srv/git";
  fcgiwrapSocket = with config.services.fcgiwrap; "${socketType}:${socketAddress}";
  cgitRoot = "${pkgs.cgit}/cgit";
  configFile = pkgs.writeText "cgitrc" ''
    scan-path=${gitRoot}
  '';
in
{
  security.acme.certs."main".extraDomainNames = [
    "git.li7g.com"
  ];

  services.fcgiwrap.enable = true;

  services.nginx.virtualHosts."git.li7g.com" = {
    forceSSL = true;
    useACMEHost = "main";

    # https://wiki.archlinux.org/title/cgit#Nginx
    root = cgitRoot;
    extraConfig = ''
      try_files @uri @cgit;
    '';
    locations."~ /.+/(info/refs|git-upload-pack)".extraConfig = ''
      fastcgi_param       SCRIPT_FILENAME     ${pkgs.git}/bin/git-http-backend;
      fastcgi_param       PATH_INFO           $uri;
      fastcgi_param       GIT_HTTP_EXPORT_ALL 1;
      fastcgi_param       GIT_PROJECT_ROOT    ${gitRoot};
      fastcgi_param       HOME                ${gitRoot};
      fastcgi_pass        ${fcgiwrapSocket};
    '';
    locations."@cgit".extraConfig = ''
      fastcgi_param       SCRIPT_FILENAME $document_root/cgit.cgi;
      fastcgi_param       PATH_INFO       $uri;
      fastcgi_param       QUERY_STRING    $args;
      fastcgi_param       HTTP_HOST       $server_name;
      fastcgi_param       CGIT_CONFIG     ${configFile};
      fastcgi_pass        ${fcgiwrapSocket};
    '';
  };
}
