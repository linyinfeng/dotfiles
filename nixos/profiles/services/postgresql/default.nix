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
  environment.global-persistence.directories = [
    config.services.postgresqlBackup.location
  ];
  systemd.tmpfiles.rules = [
    "z ${config.services.postgresqlBackup.location} 700 postgres root - -"
  ];
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
