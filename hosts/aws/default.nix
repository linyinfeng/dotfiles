{ pkgs, config, options, suites, profiles, lib, modulesPath, ... }:

{
  imports =
    suites.server ++
    (with profiles; [
      services.acme
    ]) ++ [
      (modulesPath + "/virtualisation/amazon-image.nix")
    ];

  config = lib.mkMerge [
    {
      i18n.defaultLocale = "en_US.UTF-8";
      console.keyMap = "us";
      time.timeZone = "Asia/Shanghai";

      ec2 = {
        efi = false;
        hvm = true;
      };

      swapDevices = [{ device = "/swapfile"; }];
    }

    # nginx
    {
      services.nginx = {
        enable = true;
        recommendedProxySettings = true;
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
      };
      networking.firewall.allowedTCPPorts = [
        80
        443
      ];
    }

    # acme
    {
      security.acme.certs."main" = {
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.templates.acme-credentials.path;
        domain = "aws.li7g.com";
        extraDomainNames = [
          "aws.ts.li7g.com"
        ];
      };
      sops.secrets."cloudflare-token".sopsFile = config.sops.secretsDir + /common.yaml;
      sops.templates.acme-credentials.content = ''
        CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-token}
      '';
      users.users.nginx.extraGroups = [ config.users.groups.acme.name ];
    }

    {
      networking = lib.mkIf (!config.system.is-vm) {
        useNetworkd = true;
        interfaces.ens5.useDHCP = true;
      };
    }
  ];
}
