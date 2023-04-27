{
  config,
  pkgs,
  ...
}: {
  systemd.services.matrix-qq = {
    script = ''
      # matrix-qq will write to config.yaml, always override it
      cp "$CREDENTIALS_DIRECTORY/config" config.yaml

      ${pkgs.nur.repos.linyinfeng.matrix-qq}/bin/matrix-qq \
        --config=config.yaml
    '';
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "matrix-qq";
      WorkingDirectory = "/var/lib/matrix-qq";
      LoadCredential = [
        "config:${config.sops.templates."matrix-qq-config".path}"
      ];
    };
    after = ["network-online.target" "matrix-synapse.service" "postgresql.service"];
    wants = ["network-online.target" "matrix-synapse.service" "postgresql.service"];
    wantedBy = ["multi-user.target"];
    restartTriggers = [
      config.sops.templates."matrix-qq-config".file
    ];
  };
  sops.templates."matrix-qq-config" = {
    content = builtins.toJSON {
      homeserver = {
        address = "https://matrix.li7g.com";
        domain = "li7g.com";
      };
      appservice = {
        address = "https://matrix-qq.ts.li7g.com";
        database = {
          uri = "postgres:///matrix-qq?host=/run/postgresql";
        };
        hostname = "127.0.0.1";
        port = config.ports.matrix-qq-appservice;
        provisioning.enabled = false;
        as_token = config.sops.placeholder."matrix_qq_appservice_as_token";
        hs_token = config.sops.placeholder."matrix_qq_appservice_hs_token";
      };
      bridge = {
        permissions = {
          "*" = "user";
          "@yinfeng:li7g.com" = "admin";
        };
        encryption = {
          allow = true;
        };
      };
      # QQ client protocol (1: AndroidPhone, 2: AndroidWatch, 3: MacOS, 4: QiDian, 5: IPad, 6: AndroidPad)
      qq.protocol = 5;
      logging.print_level = "debug";
    };
  };

  sops.secrets."matrix_qq_appservice_as_token" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["matrix-synapse.service" "matrix-qq.service"];
  };
  sops.secrets."matrix_qq_appservice_hs_token" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["matrix-synapse.service" "matrix-qq.service"];
  };

  services.postgresql = {
    ensureDatabases = [
      "matrix-qq"
    ];
    ensureUsers = [
      {
        name = "matrix-qq";
        ensurePermissions = {
          "DATABASE \"matrix-qq\"" = "ALL PRIVILEGES";
        };
      }
    ];
  };

  services.nginx.virtualHosts."matrix-qq.*" = {
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.matrix-qq-appservice}";
    };
  };
}
