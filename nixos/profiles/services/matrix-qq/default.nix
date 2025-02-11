{ config, pkgs, ... }:
{
  systemd.services.matrix-qq = {
    preStart = ''
      rm --force example.yaml base.yaml mixin.yaml config.yaml
      matrix-qq --generate-example-config --config=example.yaml
      cp "$CREDENTIALS_DIRECTORY/mixin.yaml" mixin.yaml
      yq eval --prettyPrint 'del(.bridge.permissions)' example.yaml >base.yaml
      yq eval-all --prettyPrint 'select(fileIndex == 0) * select(fileIndex == 1)' base.yaml mixin.yaml >config.yaml
    '';
    script = ''
      matrix-qq --config=config.yaml
    '';
    path = with pkgs; [
      nur.repos.linyinfeng.matrix-qq
      yq-go
    ];
    serviceConfig = {
      DynamicUser = true;
      StateDirectory = "matrix-qq";
      WorkingDirectory = "/var/lib/matrix-qq";
      LoadCredential = [ "mixin.yaml:${config.sops.templates."matrix-qq-config".path}" ];
    };
    after = [
      "network-online.target"
      "matrix-synapse.service"
      "postgresql.service"
    ];
    requires = [
      "network-online.target"
      "postgresql.service"
    ];
    wantedBy = [ "multi-user.target" ];
    restartTriggers = [ config.sops.templates."matrix-qq-config".file ];
  };
  sops.templates."matrix-qq-config" = {
    content = builtins.toJSON {
      bridge = {
        relay = {
          enabled = true;
          message_formats = {
            "m.text" = "{{ .Sender.DisambiguatedName }}: {{ .Message }}";
            "m.notice" = "{{ .Sender.DisambiguatedName }}: {{ .Message }}";
            "m.emote" = "* {{ .Sender.DisambiguatedName }} {{ .Message }}";
            "m.file" = "{{ .Sender.DisambiguatedName }} sent a file{{ if .Caption }}: {{ .Caption }}{{ end }}";
            "m.image" =
              "{{ .Sender.DisambiguatedName }} sent an image{{ if .Caption }}: {{ .Caption }}{{ end }}";
            "m.audio" =
              "{{ .Sender.DisambiguatedName }} sent an audio file{{ if .Caption }}: {{ .Caption }}{{ end }}";
            "m.video" =
              "{{ .Sender.DisambiguatedName }} sent a video{{ if .Caption }}: {{ .Caption }}{{ end }}";
            "m.location" =
              "{{ .Sender.DisambiguatedName }} sent a location{{ if .Caption }}: {{ .Caption }}{{ end }}";
          };
        };
        permissions = {
          "*" = "relay";
          "li7g.com" = "user";
          "@yinfeng:li7g.com" = "admin";
        };
      };
      homeserver = {
        address = "https://matrix.ts.li7g.com";
        domain = "li7g.com";
      };
      appservice = {
        id = "qq";
        address = "https://matrix-qq.ts.li7g.com";
        hostname = "127.0.0.1";
        port = config.ports.matrix-qq-appservice;
        as_token = config.sops.placeholder."matrix_qq_appservice_as_token";
        hs_token = config.sops.placeholder."matrix_qq_appservice_hs_token";
        username_template = "_qq_{{.}}";
      };
      database = {
        type = "postgres";
        uri = "postgres:///matrix-qq?host=/run/postgresql";
      };
      encryption = {
        allow = true;
      };

    };
  };

  sops.secrets."matrix_qq_appservice_as_token" = {
    terraformOutput.enable = true;
    restartUnits = [
      "matrix-synapse.service"
      "matrix-qq.service"
    ];
  };
  sops.secrets."matrix_qq_appservice_hs_token" = {
    terraformOutput.enable = true;
    restartUnits = [
      "matrix-synapse.service"
      "matrix-qq.service"
    ];
  };

  services.postgresql = {
    ensureDatabases = [ "matrix-qq" ];
    ensureUsers = [
      {
        name = "matrix-qq";
        ensureDBOwnership = true;
      }
    ];
  };

  services.nginx.virtualHosts."matrix-qq.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.matrix-qq-appservice}";
    };
  };
}
