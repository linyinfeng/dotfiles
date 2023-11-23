{
  config,
  pkgs,
  ...
}: let
  cfg = config.services.nextcloud;
in {
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.*";
    enableImagemagick = true;
    package = pkgs.nextcloud27;
    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      dbuser = "nextcloud";

      adminpassFile = config.sops.secrets."nextcloud_admin_password".path;
    };
    notify_push.enable = true;
  };
  services.postgresql = {
    ensureDatabases = ["nextcloud"];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };
  sops.secrets."nextcloud_admin_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["nextcloud-setup.service"];
    owner = "nextcloud";
  };
  services.restic.backups.b2.paths = [
    cfg.home
  ];
}
