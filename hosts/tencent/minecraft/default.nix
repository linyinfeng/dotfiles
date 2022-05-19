{ config, lib, pkgs, ... }:

let
  home = "/home/minecraft";
  port = 25565;
  rconPort = 25575;
  proxyCommandLine =
    "-Dhttp.proxyHost=localhost  -Dhttp.proxyPort=${toString config.networking.fw-proxy.mixinConfig.port}" +
    " -Dhttps.proxyHost=localhost -Dhttps.proxyPort=${toString config.networking.fw-proxy.mixinConfig.port}";
  serverProgram = "java -jar server.jar";
in
{
  systemd.services.minecraft = {
    script = ''
      rcon_password=$(cat $CREDENTIALS_DIRECTORY/rcon-password)

      yq e '.general.server.start-command = "${serverProgram}"' -i autoplug/general.yml

      # server.properties edit
      if [ -f server.properties ]; then
        echo "setup server.properties"
        sed -i "/^server-port=/ s/=.*/=${toString port}/" server.properties
        sed -i "/^enable-rcon=/ s/=.*/=true/" server.properties
        sed -i "/^rcon.password=/ s/=.*/=$rcon_password/" server.properties
        sed -i "/^rcon.port=/ s/=.*/=${toString rconPort}/" server.properties
        # disable verification
        sed -i "/^online-mode=/ s/=.*/=false/" server.properties
      fi

      # start the server
      java -Xms256m -Xmx2048m ${proxyCommandLine} -jar AutoPlug-Client.jar
    '';
    path = with pkgs; [ jre yq-go ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "minecraft";
      WorkingDirectory = "/var/lib/minecraft";
      LoadCredential = [
        "rcon-password:${config.sops.secrets."minecraft/rcon".path}"
      ];
      CPUQuota = "150%"; # at most 1.5 core (2 cores in total)
    };
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedTCPPorts = [ port rconPort ];
  networking.firewall.allowedUDPPorts = [ port rconPort ];

  sops.secrets."minecraft/rcon".sopsFile = config.sops.secretsDir + /tencent.yaml;
}
