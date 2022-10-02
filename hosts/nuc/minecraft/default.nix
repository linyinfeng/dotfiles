{ config, lib, pkgs, ... }:

let
  cfg = config.hosts.nuc;
  port = 25565; # also port for voice (udp)
  rconPort = 25575;
  mapPort = 8123;
  server = "${pkgs.mc-config-nuc.server-launcher}/bin/minecraft-server --nogui";
in
{
  imports = [
    ./backup.nix
  ];

  systemd.services.minecraft = {
    script = ''
      rcon_password=$(cat $CREDENTIALS_DIRECTORY/rcon-password)

      if [ -f eula.txt ]; then
        echo "eula=true" > eula.txt
      fi

      if [ -f server.properties ]; then
        echo "setting up server.properties..."
        sed -i "/^server-port=/ s/=.*/=${toString port}/" server.properties
        sed -i "/^enable-rcon=/ s/=.*/=true/" server.properties
        sed -i "/^rcon.password=/ s/=.*/=$rcon_password/" server.properties
        sed -i "/^rcon.port=/ s/=.*/=${toString rconPort}/" server.properties
        sed -i "/^motd=/ s/=.*/=mc.li7g.com/" server.properties
        # disable online-mode
        sed -i "/^online-mode=/ s/=.*/=false/" server.properties
      fi

      if [ -f config/bluemap/core.conf ]; then
        yq -i '.accept-download = true' config/bluemap/core.conf
        yq -i '.renderThreadCount = 2' config/bluemap/core.conf
      fi

      if [ -f config/PlasmoVoice/server.yml ]; then
        yq -i '.udp.port = ${toString port}' config/PlasmoVoice/server.yml
      fi

      if [ -f config/unifiedmetrics/config.yml ]; then
        mkdir -p config/unifiedmetrics/driver
        cp $CREDENTIALS_DIRECTORY/driver-influxdb config/unifiedmetrics/driver/influx.yml
        chmod 644 config/unifiedmetrics/driver/influx.yml
        yq -i '.metrics.driver = "influx"' config/unifiedmetrics/config.yml
      fi

      # start the server
      ${server}
    '';
    path = with pkgs; [ jre yq-go ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "minecraft";
      WorkingDirectory = "/var/lib/minecraft";
      LoadCredential = [
        "rcon-password:${config.sops.secrets."rcon_password".path}"
        "driver-influxdb:${config.sops.templates."driver-influxdb".path}"
      ];
      CPUQuota = "250%"; # at most 2 cores (4/8 cores in total)
    };
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedTCPPorts = [ port rconPort ];
  networking.firewall.allowedUDPPorts = [ port rconPort ];

  sops.secrets."rcon_password" = {
    sopsFile = config.sops.secretsDir + /terraform/hosts/nuc.yaml;
    restartUnits = [ "minecraft.service" ];
  };
  sops.secrets."influxdb_token" = {
    sopsFile = config.sops.secretsDir + /terraform/infrastructure.yaml;
    restartUnits = [ "minecraft.service" ];
  };
  sops.templates."driver-influxdb".content = builtins.toJSON {
    output = {
      url = "https://influxdb.li7g.com";
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
    onlySSL = true;
    listen = config.hosts.nuc.listens;
    useACMEHost = "main";
    locations."/".proxyPass = "http://127.0.0.1:${toString mapPort}";
  };
}
