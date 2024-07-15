{
  config,
  lib,
  pkgs,
  ...
}:
let
  port = config.ports.minecraft;
  voicePort = config.ports.minecraft-voice; # also port for voice (udp)
  rconPort = config.ports.minecraft-rcon;
  mapPort = config.ports.minecraft-map;
  server = "${pkgs.mc-config-nuc.minecraft-default-server}/bin/minecraft-server --nogui";
in
{
  imports = [ ./backup.nix ];

  systemd.services.minecraft = {
    script = ''
      rcon_password=$(cat $CREDENTIALS_DIRECTORY/rcon-password)

      if [ -f server.properties ]; then
        echo "setting up server.properties..."
        sed -i "/^server-port=/ s/=.*/=${toString port}/" server.properties
        sed -i "/^enable-rcon=/ s/=.*/=true/" server.properties
        sed -i "/^rcon.password=/ s/=.*/=$rcon_password/" server.properties
        sed -i "/^rcon.port=/ s/=.*/=${toString rconPort}/" server.properties
        sed -i "/^motd=/ s/=.*/=mc.li7g.com/" server.properties
        sed -i "/^online-mode=/ s/=.*/=true/" server.properties
        sed -i "/^enforce-secure-profile=/ s/=.*/=true/" server.properties
      fi

      if [ -f dynmap/configuration.txt ]; then
        yq -i '.webserver-port = ${toString mapPort}' dynmap/configuration.txt
      fi

      if [ -f config/voicechat/voicechat-server.properties ]; then
        sed -i "/^port=/ s/=.*/=${toString voicePort}/" config/voicechat/voicechat-server.properties
      fi

      # start the server
      exec ${server}
    '';
    path = with pkgs; [
      jre
      yq-go
    ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "minecraft";
      WorkingDirectory = "/var/lib/minecraft";
      LoadCredential = [
        "rcon-password:${config.sops.secrets."rcon_password".path}"
        "driver-influxdb:${config.sops.templates."driver-influxdb".path}"
      ];
      CPUQuota = "${toString (config.system.nproc * 50)}%";
    };
    environment.JAVA_TOOL_OPTIONS = lib.mkIf config.networking.fw-proxy.enable "-Dhttp.proxyHost=localhost -Dhttp.proxyPort=${toString config.networking.fw-proxy.ports.mixed}";
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedTCPPorts = [
    port
    rconPort
  ];
  networking.firewall.allowedUDPPorts = [ voicePort ];

  sops.secrets."rcon_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "minecraft.service" ];
  };
  sops.secrets."influxdb_token" = {
    terraformOutput.enable = true;
    restartUnits = [ "minecraft.service" ];
  };
  sops.templates."driver-influxdb".content = builtins.toJSON {
    output = {
      url = config.lib.self.data.influxdb_url;
      organization = "main-org";
      bucket = "minecraft";
      interval = 10;
    };
    authentication = {
      scheme = "TOKEN";
      token = config.sops.placeholder."influxdb_token";
    };
  };

  services.nginx.virtualHosts."mc.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/".proxyPass = "http://127.0.0.1:${toString mapPort}";
  };
}
