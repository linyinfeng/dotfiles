{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (config.networking) hostName;
  defaultTimerConfig = {
    OnCalendar = "03:00:00";
    RandomizedDelaySec = "30min";
  };
  cfgB2 = {
    repository = "b2:yinfeng-backup-${hostName}";
    environmentFile = config.sops.templates."restic-b2-env".path;
    passwordFile = config.sops.secrets."restic_password".path;
    pruneOpts = [
      "--keep-daily 3"
      "--keep-weekly 2"
    ];
  };
  cfgGarage = {
    repository = "s3:https://garage.li7g.com/backup-${hostName}";
    environmentFile = config.sops.templates."restic-garage-env".path;
    passwordFile = config.sops.secrets."restic_password".path;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
  };

  mkScript =
    {
      name,
      repository,
      environmentFile,
      passwordFile,
      ...
    }:
    pkgs.writeShellApplication {
      name = "restic-${name}";
      runtimeInputs = with pkgs; [
        restic
      ];
      text = ''
        set -o allexport
        # shellcheck disable=SC1091
        source "${environmentFile}"
        set +o allexport
        export RESTIC_PASSWORD_FILE="${passwordFile}"
        export RESTIC_REPOSITORY="${repository}"

        restic "$@"
      '';
    };
  mkServiceCfg =
    cfg:
    {
      initialize = true;
      timerConfig = lib.mkDefault defaultTimerConfig;
    }
    // cfg;

  scripts = pkgs.buildEnv {
    name = "restic-scripts";
    paths = [
      (mkScript (cfgB2 // { name = "b2"; }))
      (mkScript (cfgGarage // { name = "garage"; }))
    ];
  };
in
{
  config = {
    services.restic.backups.b2 = mkServiceCfg cfgB2;
    services.restic.backups.garage = mkServiceCfg cfgGarage;

    sops.templates."restic-b2-env".content = ''
      B2_ACCOUNT_ID="${config.sops.placeholder."b2_backup_key_id"}"
      B2_ACCOUNT_KEY="${config.sops.placeholder."b2_backup_access_key"}"
    '';
    sops.templates."restic-garage-env".content = ''
      AWS_ACCESS_KEY_ID="${config.sops.placeholder."garage_backup_key_id"}"
      AWS_SECRET_ACCESS_KEY="${config.sops.placeholder."garage_backup_access_key"}"
    '';
    sops.secrets."restic_password" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [
        "restic-backups-b2.service"
        "restic-backups-garage.service"
      ];
    };
    sops.secrets."b2_backup_key_id" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "restic-backups-b2.service" ];
    };
    sops.secrets."b2_backup_access_key" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "restic-backups-b2.service" ];
    };
    sops.secrets."garage_backup_key_id" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "restic-backups-garage.service" ];
    };
    sops.secrets."garage_backup_access_key" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "restic-backups-garage.service" ];
    };

    environment.systemPackages = [ scripts ];

    environment.global-persistence.directories = [ "/var/cache" ];
  };
}
