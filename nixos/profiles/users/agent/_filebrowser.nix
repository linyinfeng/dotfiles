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
        script = pkgs.writeShellApplication {
          name = "filebrowser-init";
          runtimeInputs = [ config.services.filebrowser.package ];
          text = ''
            PASSWORD="$(cat "$CREDENTIALS_DIRECTORY/filebrowser-admin-password")"
            filebrowser users add admin "$PASSWORD" --perm.admin 2>/dev/null || \
            filebrowser users update admin --password "$PASSWORD" --perm.admin
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
