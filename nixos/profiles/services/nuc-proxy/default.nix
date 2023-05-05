{config, ...}: {
  services.nginx.upstreams."nuc".servers = {
    "nuc.ts.li7g.com:${toString config.ports.https}" = {};
    "nuc.zt.li7g.com:${toString config.ports.https}" = {backup = true;};
    "nuc.li7g.com:${toString config.ports.https-alternative}" = {backup = true;};
  };
  services.nginx.virtualHosts."nuc-proxy.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "https://nuc";
      extraConfig = ''
        proxy_set_header Host "nuc.li7g.com";
        proxy_set_header X-Forwarded-Host "nuc.li7g.com";
      '';
    };
  };
}
