{ config, pkgs, lib, ... }:
let
  # Pin the uid so the rootless podman socket path (/run/user/<uid>/podman/podman.sock)
  # is predictable for CI's DOCKER_HOST and the app container's grading sandbox.
  uid = config.ids.uids.sicp-staging;
  composeDir = "/home/sicp-staging/oj";
in
lib.mkMerge [
  # sicp-staging: OJ compose stack isolated in a dedicated user's rootless podman
  {
    users.users.sicp-staging = {
      isSystemUser = true;
      uid = uid;
      home = "/home/sicp-staging";
      createHome = true;
      shell = pkgs.bash;
      group = config.users.groups.sicp-staging.name;
      linger = true;
      autoSubUidGidRange = true;
      packages = with pkgs; [
        docker
        docker-compose
      ];
      openssh.authorizedKeys = {
        keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPvGhmEbOZTemV1eiA1Txs/DZTpEwu/pFO70QA7O7Hm5 sicp-staging-gitlab-2026"
        ];
        inherit (config.users.users.root.openssh.authorizedKeys) keyFiles;
      };
    };
    users.groups.sicp-staging = { };

    # User-level podman socket for docker compose (DOCKER_HOST) and the app
    # container's grading sandbox. Not reachable by other host users:
    # /run/user/<uid> is 0700, so socket mode 0666 widens nothing.
    systemd.user.sockets.sicp-staging-podman = {
      listenStreams = [ "%t/podman/podman.sock" ];
      socketConfig = {
        SocketMode = "0666";
        DirectoryMode = "0700";
      };
      wantedBy = [ "sockets.target" ];
    };
    systemd.user.services.sicp-staging-podman = {
      serviceConfig = {
        ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
        Slice = "sicp-staging.slice";
      };
    };
    systemd.slices.sicp-staging = {
      sliceConfig = {
        MemoryMax = "8G";
      };
    };

    # Proxy everything to the compose stack's caddy gateway (bound to
    # 127.0.0.1:3390); path semantics (/oj/web, /oj/api) live in the in-stack
    # Caddyfile, mirroring production.
    services.nginx.virtualHosts."sicp-staging.*" = {
      forceSSL = true;
      inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.ports.sicp-staging}";
        extraConfig = ''
          client_max_body_size 10m;
        '';
      };
    };

    # App config is rendered by sops and bind-mounted into the container;
    # secrets never pass through CI.
    sops.templates."sicp-staging-application.yml" = {
      path = "${composeDir}/config/application.yml";
      owner = config.users.users.sicp-staging.name;
      mode = "0400";
      content = builtins.toJSON {
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
          oauth2 = {
            gitlab = {
              endpoint = "https://git.nju.edu.cn";
              redirectUri = "https://sicp-staging.li7g.com/oj/web/auth/callback";
              scope = "read_user";
              clientId = "824e65daa58165919d7e3137616a67818400e0610cad26a10db97234029fa508";
              clientSecret = config.sops.placeholder."nju_git_sicp_staging_oauth2";
            };
          };
          docker = {
            host = "unix:///var/run/docker.sock";
            tls-verify = false;
          };
          s3 = {
            endpoint = "http://minio:9000";
            access-key = "sicp_minio";
            secret-key = "sicp_minio";
            region = "us-east-1";
            bucket = "sicp";
          };
        };
        spring = {
          application.name = "SICP Online Judge (Staging)";
          main.banner-mode = "off";
          data = {
            mongodb = {
              host = "mongo";
              port = 27017;
              database = "sicp";
              username = "sicp_mongo";
              password = "sicp_mongo";
            };
            redis = {
              host = "redis";
              port = 6379;
              database = 0;
              password = "sicp_redis";
            };
          };
          rabbitmq = {
            host = "rabbitmq";
            port = 5672;
            username = "sicp_rabbitmq";
            password = "sicp_rabbitmq";
          };
          servlet.multipart = {
            max-file-size = "1MB";
            max-request-size = "1MB";
          };
        };
        logging.level = {
          root = "ERROR";
          "cn.edu.nju.sicp" = "INFO";
        };
        server = {
          port = 8080;
          error = {
            include-message = "always";
            whitelabel.enabled = false;
          };
        };
        management.endpoints.web.cors = {
          allowed-origins = [
            "https://sicp-staging.li7g.com"
            "http://localhost:5173"
          ];
          allowed-methods = "*";
          allowed-headers = "*";
          allowed-credentials = true;
          max-age = "3600s";
        };
      };
    };

    sops.secrets."sicp_staging_jwt_secret" = {
      terraformOutput.enable = true;
      restartUnits = [ ];
    };
    sops.secrets."sicp_staging_admin_password" = {
      terraformOutput.enable = true;
      restartUnits = [ ];
    };
    sops.secrets."nju_git_sicp_staging_oauth2" = {
      predefined.enable = true;
      restartUnits = [ ];
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
