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
  cfgMinio = {
    repository = "s3:https://minio.li7g.com/backup-${hostName}";
    environmentFile = config.sops.templates."restic-minio-env".path;
    passwordFile = config.sops.secrets."restic_password".path;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
  };

  mkScript =
    cfg:
    pkgs.substituteAll (
      {
        src = ./wrapper.sh;
        isExecutable = true;
        inherit (pkgs) restic;
      }
      // cfg
    );
  mkServiceCfg =
    cfg:
    {
      initialize = true;
      timerConfig = lib.mkDefault defaultTimerConfig;
    }
    // cfg;

  scripts = pkgs.stdenvNoCC.mkDerivation {
    name = "restic-scripts";
    buildCommand = ''
      install -Dm755 $resticB2    $out/bin/restic-b2
      install -Dm755 $resticMinio $out/bin/restic-minio
    '';
    resticB2 = mkScript cfgB2;
    resticMinio = mkScript cfgMinio;
  };
in
{
  config = {
    services.restic.backups.b2 = mkServiceCfg cfgB2;
    services.restic.backups.minio = mkServiceCfg cfgMinio;

    sops.templates."restic-b2-env".content = ''
      B2_ACCOUNT_ID="${config.sops.placeholder."b2_backup_key_id"}"
      B2_ACCOUNT_KEY="${config.sops.placeholder."b2_backup_access_key"}"
    '';
    sops.templates."restic-minio-env".content = ''
      AWS_ACCESS_KEY_ID="${config.sops.placeholder."minio_backup_key_id"}"
      AWS_SECRET_ACCESS_KEY="${config.sops.placeholder."minio_backup_access_key"}"
    '';
    sops.secrets."restic_password" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [
        "restic-backups-b2.service"
        "restic-backups-minio.service"
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
    sops.secrets."minio_backup_key_id" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "restic-backups-minio.service" ];
    };
    sops.secrets."minio_backup_access_key" = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = [ "restic-backups-minio.service" ];
    };

    environment.systemPackages = [ scripts ];

    environment.global-persistence.directories = [ "/var/cache" ];
  };
}
