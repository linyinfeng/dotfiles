{ config, ... }:
{
  services.rathole = {
    enable = true;
    role = "server";
    settings = {
      server = {
        bind_addr = "[::]:${toString config.ports.rathole}";
        services.ad-hoc = {
          bind_addr = "[::]:${toString config.ports.rathole-ad-hoc}";
        };
      };
    };
    credentialsFile = config.sops.templates."rathole-toml".path;
  };
  sops.templates."rathole-toml".content = ''
    [server.services.ad-hoc]
    token = "${config.sops.placeholder."rathole_ad_hoc_token"}"
  '';
  sops.secrets."rathole_ad_hoc_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "rathole.service" ];
  };
  networking.firewall.allowedTCPPorts = with config.ports; [
    rathole # default transport is tcp
    # rathole-ad-hoc # don't open, not secure
  ];
  services.nginx.virtualHosts."rathole-ad-hoc.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.rathole-ad-hoc}";
      extraConfig = ''
        auth_basic "rathole";
        auth_basic_user_file ${config.sops.templates."rathole-ad-hoc-auth-file".path};
      '';
    };
  };
  systemd.services.nginx.restartTriggers = [ config.sops.templates."rathole-ad-hoc-auth-file".file ];
  sops.templates."rathole-ad-hoc-auth-file" = {
    content = ''
      rathole:${config.sops.placeholder."rathole_hashed_password"}
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."rathole_hashed_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "rathole.service" ];
  };
}
