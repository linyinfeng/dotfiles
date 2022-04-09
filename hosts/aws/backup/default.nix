{ config, ... }:

let
  preBackupCalendar = "01:00:00";
  backupOnCalendar = "01:30:00";
  localBackupRoot = "/media/data/backup";
in
{
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
    location = "${localBackupRoot}/postgresql";
    startAt = preBackupCalendar;
  };

  services.restic.backups.s3 = {
    initialize = true;
    repository = "s3:https://s3.amazonaws.com/yinfeng-backup-nuc-aws";
    paths = [
      localBackupRoot
      # vaultwarden
      "/var/lib/bitwarden_rs/attachments"
      "/var/lib/bitwarden_rs/rsa_key.pem"
      "/var/lib/bitwarden_rs/rsa_key.pub.pem"
    ];
    extraOptions = [
      "s3.storage-class=STANDARD_IA"
    ];
    environmentFile = config.sops.templates."restic-s3-env".path;
    passwordFile = config.sops.secrets."restic/password".path;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
    timerConfig = { OnCalendar = backupOnCalendar; };
  };
  sops.templates."restic-s3-env".content = ''
    AWS_ACCESS_KEY_ID="${config.sops.placeholder."aws/keyId"}"
    AWS_SECRET_ACCESS_KEY="${config.sops.placeholder."aws/accessKey"}"
  '';
  sops.secrets."restic/password".sopsFile = config.sops.secretsDir + /nuc.yaml;
  sops.secrets."aws/accessKey".sopsFile = config.sops.secretsDir + /nuc.yaml;
  sops.secrets."aws/keyId".sopsFile = config.sops.secretsDir + /nuc.yaml;
}
