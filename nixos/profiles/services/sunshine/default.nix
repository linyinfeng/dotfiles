{ config, ... }:
let
  cfg = config.services.sunshine;
  inherit (config.networking) hostName;
  webPort = cfg.settings.port + 1;
in
{
  services.sunshine = {
    enable = true;
    capSysAdmin = true;
    openFirewall = true;
    settings = {
      # port = 47989; # simply use default port
      sunshine_name = hostName;
      address_family = "both";
      origin_web_ui_allowed = "pc"; # localhost only
      credentials_file = config.sops.secrets."sunshine_credentials_file".path;
    };
  };
  services.nginx.virtualHosts."${hostName}.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/sunshine" = {
      proxyPass = "https://localhost:${toString webPort}";
      extraConfig = ''
        rewrite /sunshine/(.*) /$1 break;
        proxy_ssl_verify off;
      '';
    };
  };
  sops.secrets."sunshine_credentials_file" = {
    predefined.enable = true;
    # credentials are hashed, simply make it available to all users
    mode = "440";
    group = config.users.groups.users.name;
  };
}
