{ config, ... }:
{
  services.nginx = {
    appendHttpConfig = ''
      resolver 127.0.0.53 valid=300s;
    '';
    # Names must resolve at runtime: resolving them in the config test races
    # systemd-resolved at boot (test fails -> start-limit-hit, never self-heals).
    # `resolve` needs a shared-memory `zone`; `resolver` is http/server/location-only.
    upstreams."nuc".extraConfig = ''
      zone nuc 64k;
      server nuc.ts.li7g.com:${toString config.ports.https} resolve;
      server nuc.dn42.li7g.com:${toString config.ports.https} resolve;
      server nuc.li7g.com:${toString config.ports.https-alternative} backup resolve;
    '';
    virtualHosts."nuc-proxy.*" = {
      forceSSL = true;
      inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
      serverAliases = [
        "hydra-proxy.*"
      ];
      locations."/" = {
        proxyPass = "https://nuc";
      };
    };
  };
}
