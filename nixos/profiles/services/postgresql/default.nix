{
  config,
  pkgs,
  lib,
  ...
}:
let
  newPostgres = config.specialisation.target-state-version.configuration.services.postgresql.package;
  upgradePGCluster = pkgs.writeShellApplication {
    name = "upgrade-pg-cluster";
    runtimeInputs = with pkgs; [
      systemd
      postgresql
      "/run/wrappers"
    ];
    text = ''
      systemctl stop postgresql

      export NEWDATA="/var/lib/postgresql/${newPostgres.psqlSchema}"
      export NEWBIN="${newPostgres}/bin"

      export OLDDATA="${config.services.postgresql.dataDir}"
      export OLDBIN="${config.services.postgresql.package}/bin"

      if [ "$OLDDATA" = "$NEWDATA" ]; then
        echo "the old and new data directories are same, exiting..."
        exit 1
      fi

      install -d -m 0700 -o postgres -g postgres "$NEWDATA"
      cd "$NEWDATA"
      sudo --user=postgres $NEWBIN/initdb --pgdata="$NEWDATA"

      sudo --user=postgres $NEWBIN/pg_upgrade \
        --old-datadir "$OLDDATA" --new-datadir "$NEWDATA" \
        --old-bindir $OLDBIN --new-bindir $NEWBIN \
        "$@"
    '';
  };
in
{
  services.postgresql.enable = true;

  # backup postgresql database
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
  };
  environment.global-persistence.directories = [ config.services.postgresqlBackup.location ];
  systemd.tmpfiles.rules = [ "z ${config.services.postgresqlBackup.location} 700 postgres root - -" ];
  services.restic.backups.b2 = {
    paths = [ config.services.postgresqlBackup.location ];
  };
  systemd.services."restic-backups-b2" = {
    requires = [ "postgresqlBackup.service" ];
    after = [ "postgresqlBackup.service" ];
  };

  environment.systemPackages = lib.mkIf config.system.pendingStateVersionUpgrade [ upgradePGCluster ];
}
