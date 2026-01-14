{
  config,
  pkgs,
  lib,
  ...
}:
let
  ojBase = "2024/oj";
in
lib.mkMerge [
  # online judge
  {
    systemd.services.sicp-staging-app = {
      script = ''
        exec java --add-opens "java.base/java.io=ALL-UNNAMED" \
          -Dspring.profiles.active=prod -Dspring.config.location="$CREDENTIALS_DIRECTORY/application.yml" \
          -jar "app.jar"
      '';
      path = with pkgs; [
        openjdk
      ];
      unitConfig = {
        ConditionPathExists = "/var/lib/sicp-staging/app.jar";
      };
      serviceConfig = {
        User = config.users.users.sicp-staging.name;
        Group = config.users.groups.sicp-staging.name;
        StateDirectory = "sicp-staging";
        WorkingDirectory = "/var/lib/sicp-staging";
        LoadCredential = [
          "application.yml:${config.sops.templates."sicp-staging-application.yml".path}"
        ];
      };
      restartTriggers = [
        config.sops.templates."sicp-staging-application.yml".content
      ];
      requires = [
        "sicp-staging-mongodb-setup.service"
        "sicp-staging-rabbitmq-setup.service"
      ];
      after = [
        "sicp-staging-mongodb-setup.service"
        "sicp-staging-rabbitmq-setup.service"
      ];
      wantedBy = [ "multi-user.target" ];
    };

    users.users.sicp-staging = {
      isSystemUser = true;
      shell = pkgs.bash;
      group = config.users.groups.sicp-staging.name;
      extraGroups = [
        config.users.groups.podman.name
      ];
      openssh.authorizedKeys = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGPFIcA9bW0fYc2i7aiGLaS3XaYnTCnqCCZtCKDaxG/4 sicp-staging-gitlab"
        ];
        inherit (config.users.users.root.openssh.authorizedKeys) keyFiles;
      };
    };
    users.groups.sicp-staging = { };
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            RegExp('sicp-staging-app\.service').test(action.lookup("unit")) === true &&
            subject.isInGroup("sicp-staging")) {
          return polkit.Result.YES;
        }
      });
    '';
    users.users.nginx.extraGroups = [ config.users.groups.sicp-staging.name ];

    systemd.services.sicp-staging-mongodb-setup = {
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
          "mongodb-init.js:${config.sops.templates."sicp-staging-mongodb-init.js".path}"
        ];
      };
      restartTriggers = [
        config.sops.templates."sicp-staging-mongodb-init.js".content
      ];
    };
    systemd.services.sicp-staging-rabbitmq-setup = {
      script = ''
        # initialize rabbitmq
        export RABBITMQ_ERLANG_COOKIE="$(cat /var/lib/rabbitmq/.erlang.cookie)"
        rabbitmq_sicp_staging_password="$(cat "$CREDENTIALS_DIRECTORY/rabbitmq-sicp-staging-password")"
        rabbitmqctl await_startup --timeout 300
        rabbitmqctl add_vhost sicp_staging
        rabbitmqctl add_user sicp_staging changeit || true
        rabbitmqctl change_password sicp_staging "$rabbitmq_sicp_staging_password"
        rabbitmqctl set_permissions -p sicp_staging "sicp_staging" ".*" ".*" ".*"
      '';
      after = [
        "rabbitmq.service"
      ];
      path = [
        config.services.rabbitmq.package
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = config.users.users.rabbitmq.name;
        Group = config.users.groups.rabbitmq.name;
        LoadCredential = [
          "rabbitmq-sicp-staging-password:${config.sops.secrets."rabbitmq_sicp_staging_password".path}"
        ];
      };
    };
    sops.templates."sicp-staging-mongodb-init.js".content = ''
      db = db.getSiblingDB("sicp_staging");
      if (db.getUser("sicp_staging") == null) {
        db.createUser({
          user: "sicp_staging",
          pwd: "temporary",
          roles: []
        });
      };
      db.updateUser("sicp_staging", {
        roles: [ { role: "dbOwner", db: "sicp_staging" } ]
      });
      db.changeUserPassword("sicp_staging", "${config.sops.placeholder."mongodb_sicp_staging_password"}");
    '';

    services.redis.servers.sicp-staging = {
      enable = true;
      port = config.ports.sicp-staging-redis;
      requirePassFile = config.sops.secrets."sicp_staging_redis_password".path;
    };
    sops.templates."sicp-staging-application.yml".content = builtins.toJSON {
      sicp = {
        admin = {
          username = "YINFENGLIN";
          password = config.sops.placeholder."sicp_staging_admin_password";
          fullName = "Lin Yinfeng";
        };
        jwt = {
          issuer = "sicp";
          audience = "sicp-user";
          secret = config.sops.placeholder."sicp_staging_jwt_secret";
        };
        docker = {
          host = "unix:///run/podman/podman.sock";
          tls-verify = false;
        };
        s3 = {
          endpoint = "https://minio.li7g.com";
          access-key = config.sops.placeholder."minio_sicp_staging_key_id";
          secret-key = config.sops.placeholder."minio_sicp_staging_access_key";
          region = "us-east-1";
          bucket = "sicp-staging";
        };
        oauth2 = {
          gitlab = {
            endpoint = "https://git.nju.edu.cn";
            redirectUri = "https://sicp-staging.li7g.com/${ojBase}/web/auth/callback";
            scope = "read_user";
            clientId = "824e65daa58165919d7e3137616a67818400e0610cad26a10db97234029fa508";
            clientSecret = config.sops.placeholder."nju_git_sicp_staging_oauth2";
          };
        };
      };
      spring = {
        application = {
          name = "SICP Online Judge (Staging)";
        };
        main = {
          banner-mode = "off";
        };
        data = {
          mongodb = {
            host = "localhost";
            port = config.ports.mongodb;
            database = "sicp_staging";
            username = "sicp_staging";
            password = config.sops.placeholder."mongodb_sicp_staging_password";
            # authentication-database = "sicp_staging";
          };
          redis = {
            host = "localhost";
            inherit (config.services.redis.servers.sicp-staging) port;
            database = 0;
            password = config.sops.placeholder."sicp_staging_redis_password";
          };
        };
        rabbitmq = {
          host = "localhost";
          inherit (config.services.rabbitmq) port;
          virtual-host = "sicp_staging";
          username = "sicp_staging";
          password = config.sops.placeholder."rabbitmq_sicp_staging_password";
        };
        servlet = {
          multipart = {
            max-file-size = "1MB";
            max-request-size = "1MB";
          };
        };
      };
      logging = {
        level = {
          root = "ERROR";
          "cn.edu.nju.sicp" = "INFO";
        };
      };
      server = {
        port = config.ports.sicp-staging;
        error = {
          include-message = "always";
          whitelabel = {
            enabled = false;
          };
        };
      };
      management = {
        endpoints = {
          web = {
            cors = {
              allowed-origins = [
                "https://sicp-staging.li7g.com"
                "http://localhost:5173"
                "http://localhost:3000"
              ];
              allowed-methods = "*";
              allowed-headers = "*";
              allowed-credentials = true;
              max-age = "3600s";
            };
          };
        };
      };
    };

    services.nginx.virtualHosts."sicp-staging.*" =
      let
        webDist = "/var/lib/sicp-staging/web/";
      in
      {
        forceSSL = true;
        inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
        locations."/oj".extraConfig = ''
          return 302 https://$host/${ojBase}/web/;
        '';
        locations."= /${ojBase}/web".extraConfig = ''
          return 302 https://$host$request_uri/;
        '';
        locations."/${ojBase}/web/" = {
          alias = webDist;
          index = "no-such-file"; # use @index as index
          extraConfig = ''
            try_files $uri @index;
          '';
        };
        locations."@index" = {
          root = webDist;
          extraConfig = ''
            add_header Cache-Control no-cache;
            expires 0;
            try_files /index.html =404;
          '';
        };
        locations."/api/" = {
          proxyPass = "http://127.0.0.1:${toString config.ports.sicp-staging}";
          extraConfig = ''
            rewrite /api/(.*) /$1  break;
          '';
        };
        locations."/${ojBase}/api/" = {
          proxyPass = "http://127.0.0.1:${toString config.ports.sicp-staging}";
          extraConfig = ''
            rewrite /${ojBase}/api/(.*) /$1  break;
          '';
        };
      };

    sops.secrets."sicp_staging_jwt_secret" = {
      terraformOutput.enable = true;
      restartUnits = [ "sicp-staging-app.service" ];
    };
    sops.secrets."minio_sicp_staging_key_id" = {
      terraformOutput.enable = true;
      restartUnits = [ "sicp-staging-app.service" ];
    };
    sops.secrets."minio_sicp_staging_access_key" = {
      terraformOutput.enable = true;
      restartUnits = [ "sicp-staging-app.service" ];
    };
    sops.secrets."mongodb_sicp_staging_password" = {
      terraformOutput.enable = true;
      restartUnits = [
        "sicp-staging-mongodb-setup.service"
      ];
    };
    sops.secrets."rabbitmq_sicp_staging_password" = {
      terraformOutput.enable = true;
      restartUnits = [
        "sicp-staging-rabbitmq-setup.service"
      ];
    };
    sops.secrets."sicp_staging_admin_password" = {
      terraformOutput.enable = true;
      restartUnits = [ "sicp-staging-app.service" ];
    };
    sops.secrets."sicp_staging_redis_password" = {
      terraformOutput.enable = true;
      restartUnits = [
        "sicp-staging-app.service"
        "redis-sicp-staging.service"
      ];
    };
    sops.secrets."nju_git_sicp_staging_oauth2" = {
      predefined.enable = true;
      restartUnits = [ "sicp-staging-app.service" ];
    };
  }

  # tutorials
  {
    services.nginx.virtualHosts."sicp-staging.*" = {
      locations."/tutorials/" = {
        alias = "/var/lib/sicp-staging/tutorials/";
        extraConfig = ''
          auth_basic "unreleased sicp tutorials";
          auth_basic_user_file ${config.sops.templates."sicp-tutorials-auth-file".path};
        '';
      };
    };
    systemd.services.nginx.restartTriggers = [ config.sops.templates."sicp-tutorials-auth-file".file ];
    sops.templates."sicp-tutorials-auth-file" = {
      content = ''
        sicp:${config.sops.placeholder."sicp_tutorials_hashed_password"}
      '';
      owner = config.users.users.nginx.name;
    };
    sops.secrets."sicp_tutorials_hashed_password" = {
      terraformOutput.enable = true;
      restartUnits = [ "nginx.service" ];
    };
  }
]
