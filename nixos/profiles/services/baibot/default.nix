{
  config,
  pkgs,
  ...
}:
{
  systemd.services."baibot" = {
    script = ''
      ${pkgs.linyinfeng.baibot}/bin/baibot
    '';
    serviceConfig = {
      DynamicUser = true;
      # Restart = "on-failure";
      StateDirectory = "baibot";
      EnvironmentFile = [ config.sops.templates."baibot-extra-env".path ];
    };
    environment = {
      # simply use the default configuration file
      BAIBOT_CONFIG_FILE_PATH = "${pkgs.linyinfeng.sources.baibot.src}/etc/app/config.yml.dist";
      # override default config
      BAIBOT_HOMESERVER_SERVER_NAME = "li7g.com";
      BAIBOT_HOMESERVER_URL = "https://matrix.ts.li7g.com";
      BAIBOT_USER_MXID_LOCALPART = "llm";
      BAIBOT_ACCESS_ADMIN_PATTERNS = "@yinfeng:li7g.com";
      BAIBOT_PERSISTENCE_DATA_DIR_PATH = "/var/lib/baibot";
      # no persistence encryption
      BAIBOT_PERSISTENCE_SESSION_ENCRYPTION_KEY = "";
      BAIBOT_PERSISTENCE_CONFIG_ENCRYPTION_KEY = "";
    };
    wantedBy = [ "multi-user.target" ];
  };
  sops.templates."baibot-extra-env".content = ''
    BAIBOT_USER_PASSWORD=${config.sops.placeholder."baibot/matrix-password"}
    BAIBOT_USER_ENCRYPTION_RECOVERY_PASSPHRASE=${
      config.sops.placeholder."baibot/matrix-encryption-recovery-passphrase"
    }
  '';
  sops.secrets."baibot/matrix-password" = {
    sopsFile = config.sops-file.host;
    restartUnits = [ "baibot.service" ];
  };
  sops.secrets."baibot/matrix-encryption-recovery-passphrase" = {
    sopsFile = config.sops-file.host;
    restartUnits = [ "baibot.service" ];
  };
}
