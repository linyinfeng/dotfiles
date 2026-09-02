{ config, ... }:
{
  services.nginx.virtualHosts."git.*" = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.forgejo}";
    };
  };

  services.forgejo = {
    enable = true;
    settings.server = {
      DOMAIN = "git.li7g.com";
      ROOT_URL = "https://git.li7g.com:8443/";
      HTTP_PORT = config.ports.forgejo;
      SSH_PORT = config.ports.ssh;
      START_SSH_SERVER = false;
      DISABLE_SSH = false;
    };
    settings.session.COOKIE_SECURE = true;
    settings.service.DISABLE_REGISTRATION = true;
    database = {
      type = "postgres";
      createDatabase = true;
      user = "forgejo";
      name = "forgejo";
      socket = "/run/postgresql";
    };
  };

  # INSTALL_LOCK disables the web wizard, so the initial admin is created via CLI
  sops.secrets."forgejo_admin_password" = {
    terraformOutput.enable = true;
    # unit runs as forgejo and must read the secret
    owner = "forgejo";
    group = "forgejo";
    mode = "0440";
    restartUnits = [ "forgejo-admin-init.service" ];
  };

  systemd.services.forgejo-admin-init = {
    after = [
      "forgejo.service"
      "postgresql.service"
    ];
    requires = [ "forgejo.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.forgejo.package ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = config.services.forgejo.user;
      Group = config.services.forgejo.group;
    };
    script = ''
      cfg="${config.services.forgejo.customDir}/conf/app.ini"
      # forgejo refuses to run as root; unit runs as the forgejo user
      if ! forgejo --config "$cfg" admin user list 2>/dev/null | grep -qw yinfeng; then
        forgejo --config "$cfg" admin user create \
          --username yinfeng \
          --email lin.yinfeng@outlook.com \
          --password "$(cat ${config.sops.secrets."forgejo_admin_password".path})" \
          --admin
      fi
    '';
  };
}
