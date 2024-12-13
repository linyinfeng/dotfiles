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
  refreshPGCollationVersion = pkgs.writeShellApplication {
    name = "refresh-pg-collation-version";
    runtimeInputs = with pkgs; [
      postgresql
      "/run/wrappers"
    ];
    text = ''
      db="$1"
      sudo --user=postgres psql --dbname="$db" <<EOF
      REINDEX DATABASE :DBNAME;
      ALTER DATABASE :DBNAME REFRESH COLLATION VERSION;
      EOF
    '';
  };
  refreshPGCollationVersionAll = pkgs.writeShellApplication {
    name = "refresh-pg-collation-version-all";
    runtimeInputs = with pkgs; [
      postgresql
      "/run/wrappers"
      refreshPGCollationVersion
    ];
    text = ''
      mapfile -d $'\0' -t dbs < \
        <(sudo --user=postgres psql --command='SELECT datname FROM pg_database' --no-align --tuples-only --field-separator-zero --record-separator-zero)
      for db in "''${dbs[@]}"; do
        echo "processing '$db'..."
        refresh-pg-collation-version "$db" || true
        echo
      done
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
  systemd.tmpfiles.settings."50-postgresql-backup" = {
    ${config.services.postgresqlBackup.location} = {
      z = {
        user = "postgres";
        group = "root";
        mode = "0700";
      };
    };
  };

  services.restic.backups.b2 = {
    paths = [ config.services.postgresqlBackup.location ];
  };
  systemd.services."restic-backups-b2" = {
    requires = [ "postgresqlBackup.service" ];
    after = [ "postgresqlBackup.service" ];
  };

  environment.systemPackages = lib.mkMerge [
    [
      refreshPGCollationVersion
      refreshPGCollationVersionAll
    ]
    (lib.mkIf config.system.pendingStateVersionUpgrade [ upgradePGCluster ])
  ];
}
