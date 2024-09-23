{ config, lib, ... }:
lib.mkMerge [
  # main
  {
    services.mongodb = {
      enable = true;
      enableAuth = true;
      extraConfig = ''
        net.port: ${toString config.ports.mongodb}
      '';
      initialRootPassword = "temporary"; # will be replaced in initialScript
      initialScript = config.sops.templates."mongodb-init.js".path;
    };
    sops.templates."mongodb-init.js" = {
      content = ''
        db.changeUserPassword("root", "${config.sops.placeholder."mongodb_admin_password"}")
      '';
      owner = config.services.mongodb.user;
    };
    sops.secrets."mongodb_admin_password" = {
      terraformOutput.enable = true;
      restartUnits = [ ]; # needs manual rotation
    };
  }

  # monitoring
  {
    systemd.services.mongodb-monitor-setup = {
      script = ''
        mongodb_admin_password="$(cat "$CREDENTIALS_DIRECTORY/mongodb-admin-password")"
        mongo --username root --password "$mongodb_admin_password" admin "$CREDENTIALS_DIRECTORY/mongodb-init.js"
      '';
      requires = [
        "mongodb.service"
      ];
      after = [
        "mongodb.service"
      ];
      path = [
        config.services.mongodb.package
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        LoadCredential = [
          "mongodb-admin-password:${config.sops.secrets."mongodb_admin_password".path}"
          "mongodb-init.js:${config.sops.templates."mongodb-monitor-init.js".path}"
        ];
      };
      restartTriggers = [
        config.sops.templates."mongodb-monitor-init.js".content
      ];
    };
    sops.templates."mongodb-monitor-init.js".content = ''
      if (db.getUser("monitor") == null) {
        db.createUser({
          user: "monitor",
          pwd: "temporary",
          roles: []
        });
      };
      db.updateUser("monitor", {
        roles: [ { role: "clusterMonitor", db: "admin" } ]
      });
      db.changeUserPassword("monitor", "${config.sops.placeholder."mongodb_monitor_password"}");
    '';

    services.telegraf.extraConfig.outputs.influxdb_v2 = [
      (config.lib.telegraf.mkMainInfluxdbOutput "mongodb")
    ];
    services.telegraf.extraConfig = {
      inputs = {
        mongodb = [
          {
            servers = [
              "mongodb://monitor:\${MONGODB_MONITOR_PASSWORD}@localhost:${toString config.ports.mongodb}/?connect=direct"
            ];
            tags.output_bucket = "mongodb";
          }
        ];
      };
    };
    services.telegraf.environmentFiles = [
      config.sops.templates."telegraf-mongodb-env".path
    ];
    systemd.services.telegraf = {
      requires = [ "mongodb-monitor-setup.service" ];
      after = [ "mongodb-monitor-setup.service" ];
      restartTriggers = [
        config.sops.templates."telegraf-mongodb-env".content
      ];
    };
    sops.templates."telegraf-mongodb-env".content = ''
      MONGODB_MONITOR_PASSWORD=${config.sops.placeholder."mongodb_monitor_password"}
    '';
    sops.secrets."mongodb_monitor_password" = {
      terraformOutput.enable = true;
      restartUnits = [
        "mongodb-monitor-setup.service"
        "telegraf.service"
      ];
    };
  }
]
