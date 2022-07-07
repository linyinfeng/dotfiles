{ config, lib, ... }:

let
  preBackupCalendar = "03:00:00";
  localBackupRoot = "/persist/backup";
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
    paths = [
      localBackupRoot
      # vaultwarden
      "/var/lib/bitwarden_rs/attachments"
      "/var/lib/bitwarden_rs/rsa_key.pem"
      "/var/lib/bitwarden_rs/rsa_key.pub.pem"
      # dendrite
      "/var/lib/private/dendrite/media_store"
    ];
  };
  systemd.services."restic-backups-b2" = {
    after = [ "postgresqlBackup.service" ];
  };
}
