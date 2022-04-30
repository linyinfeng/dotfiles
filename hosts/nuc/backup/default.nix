{ config, lib, ... }:

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

  services.restic.backups.b2 = {
    initialize = true;
    repository = "b2:yinfeng-backup";
    paths = [
      localBackupRoot
      # vaultwarden
      "/var/lib/bitwarden_rs/attachments"
      "/var/lib/bitwarden_rs/rsa_key.pem"
      "/var/lib/bitwarden_rs/rsa_key.pub.pem"
      # dendrite
      "/var/lib/private/dendrite/media_store"
    ];
    environmentFile = config.sops.templates."restic-b2-env".path;
    passwordFile = config.sops.secrets."restic/password".path;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
    ];
    timerConfig = { OnCalendar = backupOnCalendar; };
  };
  systemd.services."restic-backups-b2".environment =
    lib.mkIf (config.networking.fw-proxy.enable)
      config.networking.fw-proxy.environment;
  sops.templates."restic-b2-env".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder."backup/keyId"}"
    B2_ACCOUNT_KEY="${config.sops.placeholder."backup/accessKey"}"
  '';
  sops.secrets."restic/password".sopsFile = config.sops.secretsDir + /nuc.yaml;
  sops.secrets."backup/accessKey".sopsFile = config.sops.secretsDir + /nuc.yaml;
  sops.secrets."backup/keyId".sopsFile = config.sops.secretsDir + /nuc.yaml;
}
