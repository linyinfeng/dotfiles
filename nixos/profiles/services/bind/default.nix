{
  config,
  pkgs,
  ...
}: let
  commonTlsCfg = ''
    ciphers "${config.services.nginx.sslCiphers}";
    prefer-server-ciphers yes;
    ca-file "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    dhparam-file "${config.sops.secrets."dhparam_pem".path}";
  '';
in {
  services.bind = {
    enable = true;
    zones = {}; # not authority
    cacheNetworks = ["any"];
    # TODO DOT forwarders not supported in bind stable yet
    # forwarders = [];
    forwarders = [
      # cloudflare public dns
      "1.1.1.1"
      "1.0.0.1"
      "2606:4700:4700::1111"
      "2606:4700:4700::1001"
      # google public dns
      "8.8.8.8"
      "8.8.4.4"
      "2001:4860:4860::8888"
      "2001:4860:4860::8844"
    ];
    extraOptions = ''
      # TODO DOT forwarders not supported in bind stable yet
      # forwarders port 853 tls Cloudflare-DoT {
      #   1.1.1.1;
      #   1.0.0.1;
      #   2606:4700:4700::1111;
      #   2606:4700:4700::1001;
      # };
      # forwarders port 853 tls Google-DoT {
      #   8.8.8.8;
      #   8.8.4.4;
      #   2001:4860:4860::8888;
      #   2001:4860:4860::8844;
      # };
    '';
    extraConfig = ''
      http local-http-server {
        endpoints {
          "/dns-query";
        };
      }
      tls Cloudflare-DoT {
        remote-hostname "one.one.one.one";
        ${commonTlsCfg}
      };
      tls Google-DoT {
        remote-hostname "dns.google";
        ${commonTlsCfg}
      };
    '';
  };
  sops.secrets."dhparam_pem" = {
    terraformOutput.enable = true;
    restartUnits = ["bind.service"];
    owner = config.users.users.named.name;
    group = config.users.groups.named.name;
  };
}
