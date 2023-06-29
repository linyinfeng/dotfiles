{config, ...}: {
  services.nginx.upstreams."nuc".servers = {
    "nuc.ts.li7g.com:${toString config.ports.https-alternative}" = {};
    "nuc.dn42.li7g.com:${toString config.ports.https-alternative}" = {backup = true;};
    "nuc.li7g.com:${toString config.ports.https-alternative}" = {backup = true;};
  };
  services.nginx.virtualHosts."nuc-proxy.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "https://nuc";
    };
  };
}
