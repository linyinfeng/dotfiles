{ config, lib, ... }:

let
  defaultTimerConfig = { OnCalendar = "03:00:00"; };
in
{
  services.restic.backups.b2 = {
    initialize = true;
    repository = "b2:yinfeng-backup";
    environmentFile = config.sops.templates."restic-b2-env".path;
    passwordFile = config.sops.secrets."restic/password".path;
    timerConfig = lib.mkDefault defaultTimerConfig;
  };
  services.restic.backups.minio = {
    initialize = true;
    repository = "s3:https://minio.li7g.com/backup";
    environmentFile = config.sops.templates."restic-minio-env".path;
    passwordFile = config.sops.secrets."restic/password".path;
    timerConfig = lib.mkDefault defaultTimerConfig;
  };
  systemd.services."restic-backups-b2" = {
    environment =
      lib.mkIf (config.networking.fw-proxy.enable)
        config.networking.fw-proxy.environment;
  };
  systemd.services."restic-backups-minio" = {
    # environment =
    #   lib.mkIf (config.networking.fw-proxy.enable)
    #     config.networking.fw-proxy.environment;
  };
  sops.templates."restic-b2-env".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder."backup-b2/keyId"}"
    B2_ACCOUNT_KEY="${config.sops.placeholder."backup-b2/accessKey"}"
  '';
  sops.templates."restic-minio-env".content = ''
    AWS_ACCESS_KEY_ID="${config.sops.placeholder."backup-minio/keyId"}"
    AWS_SECRET_ACCESS_KEY="${config.sops.placeholder."backup-minio/accessKey"}"
  '';
  sops.secrets."restic/password".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-b2/accessKey".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-b2/keyId".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-minio/accessKey".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-minio/keyId".sopsFile = config.sops.secretsDir + /common.yaml;
}
