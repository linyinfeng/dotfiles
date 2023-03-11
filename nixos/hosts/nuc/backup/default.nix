{
  config,
  lib,
  ...
}: let
  localBackupRoot = "/media/data/backup";
in {
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
    location = "${localBackupRoot}/postgresql";
  };

  services.restic.backups.b2 = {
    paths = [
      localBackupRoot
    ];
  };
  systemd.services."restic-backups-b2" = {
    requires = ["postgresqlBackup.service"];
    after = ["postgresqlBackup.service"];
  };
}
