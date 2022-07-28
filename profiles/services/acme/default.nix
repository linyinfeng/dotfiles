{ config, ... }:

{
  security.acme = {
    acceptTerms = true;
    defaults.email = "lin.yinfeng@outlook.com";
    certs."main" = {
      dnsProvider = "cloudflare";
      credentialsFile = config.sops.templates.acme-credentials.path;
    };
  };
  sops.secrets."cloudflare_token" = {
    sopsFile = config.sops.secretsDir + /terraform/common.yaml;
    restartUnits = [ ]; # no need to restart units
  };
  sops.templates.acme-credentials.content = ''
    CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare_token"}
  '';
  users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
}
