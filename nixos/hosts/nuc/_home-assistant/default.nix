{ config, pkgs, ... }:
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    package = pkgs.home-assistant.override {
      extraPackages =
        p: with p; [
          gtts
          radios
          hap-python
        ];
    };
    config = {
      # Loads default set of integrations. Do not remove.
      # https://github.com/XiaoMi/ha_xiaomi_home/issues/504
      default_config = { };
      homeassistant = {
        name = "Yinfeng's";
        latitude = "!secret latitude";
        longitude = "!secret longitude";
        elevation = "!secret elevation";
        unit_system = "metric";
      };
      http = {
        server_host = [
          "::1"
          "192.168.0.2"
        ];
        server_port = config.ports.home-assistant;
        use_x_forwarded_for = true;
        trusted_proxies = [ "::1" ];
      };
    };
    customComponents = with pkgs.home-assistant-custom-components; [
      xiaomi_miot
      xiaomi_home
    ];
  };
  services.nginx.virtualHosts."home-assistant.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://[::1]:${toString config.ports.home-assistant}";
      proxyWebsockets = true;
    };
  };
  systemd.services."avahi-publish-hass" = {
    description = "Publish homeassistant.local";
    script = ''
      avahi-publish --address --no-reverse homeassistant.local 192.168.0.2
    '';
    path = [ config.services.avahi.package ];
    wantedBy = [ "multi-user.target" ];
  };
  sops.templates."home-assistant-secrets" = {
    content = ''
      latitude: ${config.sops.placeholder."home_latitude"}
      longitude: ${config.sops.placeholder."home_longitude"}
      elevation: ${config.sops.placeholder."home_elevation"}
    '';
    owner = "hass";
    group = "hass";
    mode = "0400";
  };
  systemd.tmpfiles.settings."90-hass-secrets" = {
    "${config.services.home-assistant.configDir}/secrets.yaml" = {
      "L+" = {
        argument = config.sops.templates."home-assistant-secrets".path;
      };
    };
  };
  systemd.services.home-assistant.restartTriggers = [
    config.sops.templates."home-assistant-secrets".content
  ];
  sops.secrets."home_latitude" = {
    predefined.enable = true;
    restartUnits = [ "home-assistant.service" ];
  };
  sops.secrets."home_longitude" = {
    predefined.enable = true;
    restartUnits = [ "home-assistant.service" ];
  };
  sops.secrets."home_elevation" = {
    predefined.enable = true;
    restartUnits = [ "home-assistant.service" ];
  };
}
