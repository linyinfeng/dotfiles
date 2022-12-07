{ config, ... }:

{
  services.nginx.virtualHosts."elasticsearch-proxy.*" = {
    addSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "https://elasticsearch.li7g.com";
      extraConfig = ''
        auth_basic "elasticsearch";
        proxy_ssl_server_name on;
        proxy_set_header Host elasticsearch.li7g.com;
        proxy_set_header X-Forwarded-Host elasticsearch.li7g.com;
        include ${config.sops.templates."elasticsearch-proxy-set-header".path};
      '';
    };
  };
  systemd.services.nginx.restartTriggers = [
    config.sops.templates."elasticsearch-proxy-set-header".file
  ];
  sops.templates."elasticsearch-proxy-set-header" = {
    content = ''
      proxy_set_header Authorization "Basic ${config.sops.placeholder."elasticsearch_auth_header"}";
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."elasticsearch_auth_header" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/${config.networking.hostName}.yaml;
    restartUnits = [ "nginx.service" ];
  };
}
