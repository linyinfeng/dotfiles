{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.networking) hostName;
  inherit (config.lib.self.data) b2_s3_api_host b2_s3_region;

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

  # the WAL archive queue is written by postgres (archive-push) and read by the
  # backup jobs (archive-check), so it lives outside PGDATA and is group-writable
  spoolDir = "/var/spool/pgbackrest";
  pgbackrestEnv = config.sops.templates."pgbackrest-env".path;
  pgbackrestJobs = [
    "pgbackrest-default-full"
    "pgbackrest-default-diff"
  ];
in
{
  services.postgresql.enable = true;

  # a replication slot retains WAL forever at the -1 default; the barman setup this
  # profile used to carry left one behind and filled the disk
  services.postgresql.settings.max_slot_wal_keep_size = "10GB";

  # weekly full + daily diff: block incremental only ships the changed blocks, which
  # keeps the diffs small while restore still walks a short chain
  services.pgbackrest = {
    enable = true;

    settings = {
      compress-type = "zst";
      process-max = 2;
      start-fast = true;
      # a slow object store push must not stall WAL reuse
      archive-async = true;
      # drop the queue rather than fill pg_wal when the repository is unreachable
      # for long enough; a new backup restores full recoverability
      archive-push-queue-max = "1GiB";
      spool-path = spoolDir;
    };

    repos.b2 = {
      type = "s3";
      s3-bucket = "yinfeng-backup-${hostName}";
      s3-endpoint = b2_s3_api_host;
      s3-region = b2_s3_region;
      s3-uri-style = "path";
      path = "/pgbackrest";
      # bundling first, block incremental depends on it and object stores prefer
      # fewer, larger files
      bundle = true;
      block = true;
      cipher-type = "aes-256-cbc";
      retention-full = 2;
      retention-diff = 7;
      retention-history = 30;
    };

    stanzas.default.jobs = {
      full = {
        schedule = "Sun 03:00";
        type = "full";
      };
      diff = {
        schedule = "Mon..Sat 03:00";
        type = "diff";
      };
    };
  };

  # archive-push runs as postgres while the backup jobs run as pgbackrest: both read
  # the credentials from the same rendered file
  systemd.services =
    (lib.genAttrs pgbackrestJobs (_: {
      serviceConfig.EnvironmentFile = pgbackrestEnv;
    }))
    // {
      # ProtectSystem=strict leaves the spool read-only otherwise
      postgresql.serviceConfig = {
        EnvironmentFile = pgbackrestEnv;
        ReadWritePaths = [ spoolDir ];
      };

      pgbackrest-check = {
        description = "pgBackRest repository check";
        serviceConfig = {
          Type = "oneshot";
          User = "pgbackrest";
          Group = "pgbackrest";
          EnvironmentFile = pgbackrestEnv;
          ExecStart = "${lib.getExe pkgs.pgbackrest} --stanza=default check";
        };
      };
    };

  systemd.timers.pgbackrest-check = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon 04:00";
      Persistent = true;
    };
  };

  systemd.tmpfiles.rules = [ "d ${spoolDir} 0770 pgbackrest pgbackrest -" ];
  environment.global-persistence.directories = [ spoolDir ];

  sops.templates."pgbackrest-env" = {
    owner = "root";
    group = "pgbackrest";
    mode = "0440";
    content = ''
      PGBACKREST_REPO1_S3_KEY="${config.sops.placeholder."b2_backup_key_id"}"
      PGBACKREST_REPO1_S3_KEY_SECRET="${config.sops.placeholder."b2_backup_access_key"}"
      PGBACKREST_REPO1_CIPHER_PASS="${config.sops.placeholder."pgbackrest_cipher_pass"}"
    '';
  };
  sops.secrets = {
    b2_backup_key_id = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
    };
    b2_backup_access_key = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
    };
    pgbackrest_cipher_pass = {
      terraformOutput = {
        enable = true;
        perHost = true;
      };
      restartUnits = map (job: "${job}.service") pgbackrestJobs;
    };
  };

  environment.systemPackages = lib.mkMerge [
    [
      refreshPGCollationVersion
      refreshPGCollationVersionAll
    ]
    (lib.mkIf config.system.pendingStateVersionUpgrade [ upgradePGCluster ])
  ];
}
