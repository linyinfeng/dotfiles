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
    ];
  };
  systemd.services."restic-backups-b2" = {
    after = [ "postgresqlBackup.service" ];
  };
}
