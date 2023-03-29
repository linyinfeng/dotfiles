{
  config,
  lib,
  ...
}: {
  services.postgresql.enable = true;

  # backup postgresql database
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
  };
  services.restic.backups.b2 = {
    paths = [
      config.services.postgresqlBackup.location
    ];
  };
  systemd.services."restic-backups-b2" = {
    requires = ["postgresqlBackup.service"];
    after = ["postgresqlBackup.service"];
  };
}
