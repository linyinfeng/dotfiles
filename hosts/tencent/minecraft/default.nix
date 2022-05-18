{ config, lib, pkgs, ... }:

let
  home = "/home/minecraft";
  port = 25565;
  rconPort = 25575;
  proxyCommandLine =
    " -Dhttp.proxyHost=localhost  -Dhttp.proxyPort=${toString config.networking.fw-proxy.mixinConfig.port}" +
    " -Dhttps.proxyHost=localhost -Dhttps.proxyPort=${toString config.networking.fw-proxy.mixinConfig.port}";
  serverProgram = "${pkgs.papermc}/bin/minecraft-server -Xms256m -Xmx2048m ${proxyCommandLine}";
in
{
  systemd.services.minecraft = {
    script = ''
      rcon_password=$(cat $CREDENTIALS_DIRECTORY/rcon-password)

      echo "eula=true" > eula.txt

      yq e '.general.server.start-command = "${serverProgram}"' -i autoplug/general.yml

      # server.properties edit
      if [ -f server.properties ]; then
        sed "/^server-port=/ s/=.*/=${toString port}/" server.properties
        sed "/^enable-rcon=/ s/=.*/=true/" server.properties
        sed "/^rcon.password=/ s/=.*/=$rcon_password/" server.properties
        sed "/^rcon.port=/ s/=.*/=${toString rconPort}/" server.properties
      fi

      # start the server
      java ${proxyCommandLine} -jar AutoPlug-Client.jar
    '';
    path = with pkgs; [ papermc jre yq-go ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "minecraft";
      WorkingDirectory = "/var/lib/minecraft";
      LoadCredential = [
        "rcon-password:${config.sops.secrets."minecraft/rcon".path}"
      ];
      CPUQuota = "100%"; # at most 1 core (2 cores in total)
    };
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedTCPPorts = [ port ];
  networking.firewall.allowedUDPPorts = [ port ];

  sops.secrets."minecraft/rcon".sopsFile = config.sops.secretsDir + /tencent.yaml;
}
