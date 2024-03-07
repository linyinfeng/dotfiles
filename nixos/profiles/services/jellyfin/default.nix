{
  config,
  pkgs,
  lib,
  ...
}: let
  user = config.services.jellyfin.user;
in {
  services.jellyfin = {
    enable = true;
  };
  users.users.${user} = {
    shell = pkgs.fish; # for media storage operation
    home = "/var/lib/jellyfin-media";
    createHome = true;
    extraGroups = [
      config.users.groups.transmission.name
    ];
  };

  systemd.services.jellyfin-setup = {
    script = ''
      xmlstarlet edit --inplace --update "/NetworkConfiguration/HttpServerPortNumber" --value "${toString config.ports.jellyfin}" network.xml
    '';
    path = with pkgs; [
      xmlstarlet
    ];
    unitConfig = {
      ConditionPathExists = config.services.jellyfin.configDir;
    };
    serviceConfig = {
      Type = "oneshot";
      WorkingDirectory = config.services.jellyfin.configDir;
      User = "jellyfin";
      Group = "jellyfin";
    };
    wantedBy = ["jellyfin.service"];
    before = ["jellyfin.service"];
  };
  systemd.services.jellyfin = {
    # faster metadata search
    environment =
      lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
  };

  services.nginx.virtualHosts."jellyfin.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."= /" = {
      extraConfig = ''
        return 302 /web/;
      '';
    };
    locations."/" = {
      proxyPass = "http://localhost:${toString config.ports.jellyfin}";
      extraConfig = ''
        proxy_buffering off;
      '';
    };
    locations."= /web/".proxyPass = "http://localhost:${toString config.ports.jellyfin}/web/index.html";
    locations."/socket" = {
      proxyPass = "http://localhost:${toString config.ports.jellyfin}";
      extraConfig = ''
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
      '';
    };
  };

  # for vaapi support
  hardware.opengl.enable = true;

  # https://jellyfin.org/docs/general/networking/index.html
  networking.firewall = {
    allowedUDPPorts = with config.ports; [
      jellyfin-auto-discovery-1
      jellyfin-auto-discovery-1
    ];
  };
}
