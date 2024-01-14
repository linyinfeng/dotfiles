{
  config,
  pkgs,
  ...
}: let
  inherit (config.lib.self) data;
  dotPort = config.ports.dns-over-tls;
  dohEndpoint = "/dns-query";
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
      listen-on    port ${toString dotPort} tls local { any; };
      listen-on-v6 port ${toString dotPort} tls local { any; };
      listen-on-v6 port ${toString config.ports.bind-http} tls none http local { any; };

      # TODO DOT forwarders not supported in bind stable yet
      # forwarders port 853 tls cloudflare {
      #   1.1.1.1;
      #   1.0.0.1;
      #   2606:4700:4700::1111;
      #   2606:4700:4700::1001;
      # };
      # forwarders port 853 tls google {
      #   8.8.8.8;
      #   8.8.4.4;
      #   2001:4860:4860::8888;
      #   2001:4860:4860::8844;
      # };
    '';
    extraConfig = ''
      http local {
        endpoints {
          "${dohEndpoint}";
        };
      };
      tls local {
        cert-file "${config.security.acme.tfCerts."li7g_com".fullChain}";
        key-file  "${config.security.acme.tfCerts."li7g_com".key}";
        ciphers "${config.services.nginx.sslCiphers}";
      };
      tls cloudflare {
        remote-hostname "one.one.one.one";
        ${commonTlsCfg}
      };
      tls google {
        remote-hostname "dns.google";
        ${commonTlsCfg}
      };
    '';
  };
  services.nginx.virtualHosts."dns.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/hostname".extraConfig = ''
      return 200 "${config.networking.hostName}";
    '';
    locations.${dohEndpoint}.extraConfig = ''
      grpc_pass grpc://[::1]:${toString config.ports.bind-http};
    '';
  };
  networking.dn42.autonomousSystem.thisHost.addressesV6 = [
    data.dn42_anycast_dns_v6
  ];
  environment.etc."bind/rndc.key".source = config.sops.secrets."bind_rndc_config".path;
  users.users.named.extraGroups = [config.users.groups.acmetf.name];
  networking.firewall.allowedTCPPorts = [
    dotPort
  ];
  environment.systemPackages = [
    # for rndc cli
    config.services.bind.package
  ];
  sops.secrets."dhparam_pem" = {
    terraformOutput.enable = true;
    restartUnits = ["bind.service"];
    owner = config.users.users.named.name;
    group = config.users.groups.named.name;
  };
  sops.secrets."bind_rndc_config" = {
    terraformOutput.enable = true;
    restartUnits = ["bind.service"];
    owner = config.users.users.named.name;
    group = config.users.groups.named.name;
  };
}
