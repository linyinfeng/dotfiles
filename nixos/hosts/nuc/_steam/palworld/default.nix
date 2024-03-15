{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.palworld;
  gameHome = config.users.users.steam.home;
  rootDir' = "Games/palworld";
  rootDir = "${gameHome}/${rootDir'}";
  configFilePath = "${rootDir}/Pal/Saved/Config/LinuxServer/PalWorldSettings.ini";
  defaultConfigFilePath = "${rootDir}/DefaultPalWorldSettings.ini";
  appId = "2394010";
  palworldRcon = pkgs.writeShellApplication {
    name = "palworld-rcon";
    runtimeInputs = with pkgs; [ nur.repos.linyinfeng.rcon-cli ];
    text = ''
      gorcon --address "localhost:${toString config.ports.palworld-rcon}" \
             --password "$(cat "${config.sops.secrets."palworld_admin_password".path}")" \
             "$@"
    '';
  };
in
{
  imports = [ ./backup.nix ];
  options = {
    services.palworld = {
      saveDirectory = lib.mkOption {
        type = lib.types.str;
        default = "${rootDir}/Pal/Saved";
        readOnly = true;
      };
      settings = lib.mkOption {
        type = with lib.types; attrsOf str;
        default = { };
      };
      extraOptions = lib.mkOption {
        type = with lib.types; listOf str;
        default = [ ];
      };
    };
  };
  config = {
    services.palworld.settings = {
      # currently nothing
    };
    services.palworld.extraOptions = [
      "-servername=palworld.li7g.com"
      "-port=${toString config.ports.palworld}"
      "-publicport=${toString config.ports.palworld}"
      "-queryport=${toString config.ports.palworld-query}"
      "-RCONEnabled=true"
      "-RCONPort=${toString config.ports.palworld-rcon}"
      "EpicApp=PalServer"
      "-useperfthreads"
      "-NoAsyncLoadingThread"
      "-UseMultithreadForDS"
    ];

    home-manager.users.steam.home.global-persistence.directories = [ rootDir' ];
    systemd.services.palworld = {
      preStart = ''
        # install game
        steamcmd \
          +force_install_dir "${rootDir}" \
          +login anonymous \
          +app_update "${appId}" validate \
          +quit

        # modify settings
        mkdir --parents --verbose $(dirname "${configFilePath}")
        cp --verbose "${defaultConfigFilePath}" "${configFilePath}"

        ${lib.concatMapStringsSep "\n" (s: ''
          sed --in-place 's/${s.name}=[^,)]*\([,)]\)/${s.name}=${s.value}\1/' "${configFilePath}"
        '') (lib.attrsToList cfg.settings)}
      '';
      script = ''
        function shutdown() {
          echo "sending save command..."
          palworld-rcon save
          echo "sending shutdown command..."
          palworld-rcon "shutdown 1"
          echo "waiting for exit..."
          wait "$killpid"
          echo "exiting..."
          exit 0
        }
        trap 'shutdown' SIGTERM

        # fix loading of steamclient.so
        export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${rootDir}/linux64"
        steam-run ./PalServer.sh \
          -serverpassword="$(cat "$CREDENTIALS_DIRECTORY/server-password")" \
          -adminpassword="$(cat "$CREDENTIALS_DIRECTORY/admin-password")" \
          ${lib.escapeShellArgs cfg.extraOptions} \
          &
        killpid="$!"
        wait "$killpid"
      '';
      path = with pkgs; [
        steamcmd
        steam-run
        palworldRcon
      ];
      serviceConfig = {
        User = "steam";
        Group = "steam";
        CPUQuota = "400%"; # at most 4 core (8 cores in total)
        WorkingDirectory = "-${rootDir}";
        Restart = "always";
        MemoryMax = "16G";
        RuntimeMaxSec = "4h";
        KillMode = "mixed";
        TimeoutStopSec = "5m";
        LoadCredential = [
          "admin-password:${config.sops.secrets."palworld_admin_password".path}"
          "server-password:${config.sops.secrets."palworld_server_password".path}"
        ];
      };
      wantedBy = [ "multi-user.target" ];
    };
    environment.systemPackages = [ palworldRcon ];
    networking.firewall.allowedTCPPorts = [ config.ports.palworld-rcon ];
    networking.firewall.allowedUDPPorts = [
      config.ports.palworld
      config.ports.palworld-query
    ];
    sops.secrets."palworld_admin_password" = {
      terraformOutput.enable = true;
      restartUnits = [ "palworld.service" ];
      owner = "steam";
    };
    sops.secrets."palworld_server_password" = {
      terraformOutput.enable = true;
      restartUnits = [ "palworld.service" ];
      owner = "steam";
    };
  };
}
