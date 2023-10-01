{
  config,
  lib,
  ...
}: {
  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "lin.yinfeng@outlook.com";
      dnsProvider = "cloudflare";
      dnsResolver = "1.1.1.1:53";
      credentialsFile = config.sops.templates.acme-credentials.path;
    };
  };
  systemd.services.acme-main.environment =
    lib.mkIf (config.networking.fw-proxy.enable)
    config.networking.fw-proxy.environment;
  sops.secrets."cloudflare_token" = {
    sopsFile = config.sops-file.get "terraform/common.yaml";
    restartUnits = []; # no need to restart units
  };
  sops.templates.acme-credentials.content = ''
    CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare_token"}
  '';
  users.users.nginx.extraGroups = [config.users.groups.acme.name];

  security.acme.certs."main" = {
    domain = "*.li7g.com";
    extraDomainNames = [
      "*.zt.li7g.com" # zerotier
      "*.ts.li7g.com" # tailscale
      "*.dn42.li7g.com" # dn42
      # workaround for https://letsencrypt.org/docs/duplicate-certificate-limit
      "${config.networking.hostName}.endpoints.li7g.com"
    ];
  };
}
