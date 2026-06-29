{ config, pkgs, ... }:
{
  services.filebrowser = {
    enable = true;
    settings = {
      root = "/home/agent";
      port = config.ports.filebrowser-agent;
    };
    user = "agent";
  };

  services.nginx.virtualHosts."agent.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings)
      sslCertificate
      sslCertificateKey
      ;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.filebrowser-agent}";
    };
  };

  systemd.services.filebrowser = {
    preStart =
      let
        database = config.services.filebrowser.settings.database;
        script = pkgs.writeShellApplication {
          name = "filebrowser-init";
          runtimeInputs = [ config.services.filebrowser.package ];
          text = ''
            database="${database}"
            cd "$(dirname "$database")"
            echo "filebrowser-init: initializing database at $database"
            if ! filebrowser config init --database="$database"; then
              echo "filebrowser-init: database already initialized, skipping"
            fi
            PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/filebrowser-admin-password")"
            echo "filebrowser-init: setting admin password"
            if filebrowser users add admin "$PASSWORD" --perm.admin --database="$database"; then
              echo "filebrowser-init: admin user created"
            else
              echo "filebrowser-init: admin user already exists, updating password"
              filebrowser users update admin --password "$PASSWORD" --perm.admin --database="$database"
            fi
          '';
        };
      in
      "${script}/bin/filebrowser-init";
    serviceConfig.LoadCredential = [
      "filebrowser-admin-password:${config.sops.secrets."filebrowser_agent_admin_password".path}"
    ];
  };

  sops.secrets."filebrowser_agent_admin_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "filebrowser.service" ];
  };
}
