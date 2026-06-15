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
      REINDEX DATABASE :"DBNAME";
      ALTER DATABASE :"DBNAME" REFRESH COLLATION VERSION;
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
  backupDir = "/var/backup/postgresql";
  barmanService =
    cfg:
    lib.recursiveUpdate {
      serviceConfig = {
        StateDirectory = "barman";
        User = config.users.users.barman.name;
        Group = config.users.groups.barman.name;
      };
      path = with pkgs; [
        barman
        postgresql
      ];
      after = [ "postgresql.service" ];
    } cfg;
in
lib.mkMerge [
  {
    services.postgresql.enable = true;

    environment.systemPackages = lib.mkMerge [
      [
        refreshPGCollationVersion
        refreshPGCollationVersionAll
      ]
      (lib.mkIf config.system.pendingStateVersionUpgrade [ upgradePGCluster ])
    ];
  }

  {
    users.users.barman = {
      isSystemUser = true;
      group = config.users.groups.barman.name;
    };
    users.groups.barman = { };
    services.postgresql.ensureUsers = [
      {
        name = "barman";
        ensureClauses = {
          superuser = true;
        };
      }
    ];
    services.postgresql = {
      settings.wal_level = "replica";
      authentication = ''
        # allow local replication connection from barman
        local replication barman trust
      '';
    };
    systemd.tmpfiles.rules = [
      "d '/var/lib/barman' 0700 barman barman - -"
      "d '${backupDir}' 0700 barman barman - -"
    ];
    environment.systemPackages = with pkgs; [
      barman
    ];
    environment.etc."barman.conf".text = ''
      [barman]
      barman_user = ${config.users.users.barman.name}
      barman_home = /var/lib/barman
      configuration_files_directory = /etc/barman.d
    '';
    environment.etc."barman.d/local.conf".text = ''
      [local]
      description = "Local barman backup server"

      backup_method = postgres
      slot_name = barman
      create_slot = auto

      streaming_conninfo = user=barman dbname=postgres
      conninfo = user=barman dbname=postgres

      backup_directory = ${backupDir}
      streaming_archiver = on

      last_backup_maximum_age = 7 DAYS
      retention_policy = RECOVERY WINDOW OF 7 DAYS
      wal_retention_policy = main
    '';
    systemd.services.barman-receive-wal = barmanService {
      script = ''
        barman receive-wal --create-slot --if-not-exists local
        exec barman receive-wal local
      '';
      wantedBy = [ "postgresql.service" ];
    };
    systemd.services.barman-cron = barmanService {
      script = ''
        exec barman cron
      '';
      requires = [ "barman-receive-wal.service" ];
      after = [
        "postgresql.service"
        "barman-receive-wal.service"
      ];
    };
    systemd.timers.barman-cron = {
      timerConfig = {
        OnCalendar = "hourly";
      };
      wantedBy = [ "postgresql.service" ];
    };
    services.restic.backups.b2 = {
      paths = [ backupDir ];
    };
    systemd.services."restic-backups-b2" = {
      requires = [ "barman-cron.service" ];
      after = [ "barman-cron.service" ];
    };
  }
]
