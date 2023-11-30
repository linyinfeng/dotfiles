{
  config,
  lib,
  pkgs,
  ...
}: let
  port = config.ports.minecraft; # also port for voice (udp)
  rconPort = config.ports.minecraft-rcon;
  mapPort = config.ports.minecraft-map;
  server = "${pkgs.mc-config-nuc.minecraft-default-server}/bin/minecraft-server --nogui";
in {
  imports = [
    ./backup.nix
  ];

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
        # # disable online-mode
        # sed -i "/^online-mode=/ s/=.*/=false/" server.properties
        # disable enforce-secure-profile
        sed -i "/^enforce-secure-profile=/ s/=.*/=false/" server.properties
      fi

      if [ -f dynmap/configuration.txt ]; then
        yq -i '.webserver-port = ${toString mapPort}' dynmap/configuration.txt
      fi

      # if [ -f config/PlasmoVoice/server.yml ]; then
      #   yq -i '.udp.port = ${toString port}' config/PlasmoVoice/server.yml
      # fi

      if [ -f config/unifiedmetrics/config.yml ]; then
        mkdir -p config/unifiedmetrics/driver
        cp $CREDENTIALS_DIRECTORY/driver-influxdb config/unifiedmetrics/driver/influx.yml
        chmod 644 config/unifiedmetrics/driver/influx.yml
        yq -i '.metrics.driver = "influx"' config/unifiedmetrics/config.yml
      fi

      if [ -f config/EssentialCommands.properties ]; then
        sed -i "/^use_permissions_api=/ s/=.*/=true/" config/EssentialCommands.properties
        sed -i "/^home_limit=/ s/=.*/=[1, 10, 100]/" config/EssentialCommands.properties
      fi

      # start the server
      ${server}
    '';
    path = with pkgs; [jre yq-go];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "minecraft";
      WorkingDirectory = "/var/lib/minecraft";
      LoadCredential = [
        "rcon-password:${config.sops.secrets."rcon_password".path}"
        "driver-influxdb:${config.sops.templates."driver-influxdb".path}"
      ];
      CPUQuota = "400%"; # at most 2 cores (4/8 cores in total)
    };
    environment.JAVA_TOOL_OPTIONS =
      lib.mkIf config.networking.fw-proxy.enable
      "-Dhttp.proxyHost=localhost -Dhttp.proxyPort=${toString config.networking.fw-proxy.ports.mixed}";
    wantedBy = ["multi-user.target"];
  };
  networking.firewall.allowedTCPPorts = [port rconPort];
  networking.firewall.allowedUDPPorts = [port rconPort];

  sops.secrets."rcon_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["minecraft.service"];
  };
  sops.secrets."influxdb_token" = {
    sopsFile = config.sops-file.get "terraform/infrastructure.yaml";
    restartUnits = ["minecraft.service"];
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
