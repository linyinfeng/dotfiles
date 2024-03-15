{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.lib.self) data;
  certOptions =
    { config, name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        certificate = lib.mkOption { type = lib.types.path; };
        issuer = lib.mkOption { type = lib.types.path; };
        fullChain = lib.mkOption { type = lib.types.path; };
        key = lib.mkOption { type = lib.types.path; };
        nginxSettings = lib.mkOption {
          type = lib.types.attrs;
          readOnly = true;
          default = {
            sslCertificate = config.fullChain;
            sslCertificateKey = config.key;
          };
        };
      };
    };
in
{
  options.security.acme.tfCerts = lib.mkOption {
    type = with lib.types; attrsOf (submodule certOptions);
  };
  config = lib.mkMerge [
    # acme service
    {
      security.acme = {
        acceptTerms = true;
        defaults = {
          email = "lin.yinfeng@outlook.com";
          dnsProvider = "cloudflare";
          credentialsFile = config.sops.templates.acme-credentials.path;
        };
      };
      sops.secrets."cloudflare_token" = {
        terraformOutput.enable = true;
        restartUnits = [ ]; # no need to restart units
      };
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder."cloudflare_token"}
      '';
      users.users.nginx.extraGroups = lib.mkIf (config.security.acme.certs != { }) [
        config.users.groups.acme.name
      ];

      # disabled, use tf-managed acme certs
      # security.acme.certs."main" = {
      #   domain = "*.li7g.com";
      #   extraDomainNames = [
      #     "*.zt.li7g.com" # zerotier
      #     "*.ts.li7g.com" # tailscale
      #     "*.dn42.li7g.com" # dn42
      #     # workaround for https://letsencrypt.org/docs/duplicate-certificate-limit
      #     "${config.networking.hostName}.endpoints.li7g.com"
      #   ];
      # };
    }

    # tf-managed certs
    {
      users.users.acmetf = {
        isSystemUser = true;
        group = "acmetf";
      };
      users.groups.acmetf = { };
      users.users.nginx.extraGroups = [ config.users.groups.acmetf.name ];

      security.acme.tfCerts."li7g_com" = {
        certificate = pkgs.writeTextFile {
          name = "certificate.pem";
          text = data.acme_li7g_com_certificate_pem;
        };
        issuer = pkgs.writeTextFile {
          name = "issuer.pem";
          text = data.acme_li7g_com_issuer_pem;
        };
        fullChain = pkgs.writeTextFile {
          name = "full-chain.pem";
          text = data.acme_li7g_com_full_chain_pem;
        };
        key = config.sops.secrets."acme_li7g_com_private_key_pem".path;
      };
      sops.secrets."acme_li7g_com_private_key_pem" = {
        terraformOutput.enable = true;
        owner = "acmetf";
        group = "acmetf";
        mode = "440";
        restartUnits = [ ]; # no need to restart units
      };
    }

    # nginx
    { }
  ];
}
