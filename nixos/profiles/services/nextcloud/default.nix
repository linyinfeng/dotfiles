{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.nextcloud;
  version = 27;
  package = pkgs."nextcloud${toString version}";
  inherit (package.packages) apps;

  exifRename = pkgs.writeShellApplication {
    name = "exif-rename";
    runtimeInputs = with pkgs; [
      exiftool
    ];
    text = ''
      exiftool \
        -fileOrder DateTimeOriginal \
        -recurse \
        -ignoreMinorErrors \
        '-FileName<CreateDate' \
        -d %Y/%m/%Y-%m-%dT%H:%M:%S%%-.3c.%%e \
        -api LargeFileSupport=1 \
        "$@"
    '';
  };
in {
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.li7g.com";
    https = true;
    enableImagemagick = true;
    inherit package;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.sops.secrets."nextcloud_admin_password".path;

      extraTrustedDomains = [
        "nextcloud.ts.li7g.com"
        "nextcloud.dn42.li7g.com"
      ];
      defaultPhoneRegion = "CN";
    };
    extraOptions = {
      mail_smtpmode = "smtp";
      mail_smtphost = "smtp.ts.li7g.com";
      mail_smtpport = config.ports.smtp-starttls;
      mail_from_address = "nextcloud";
      mail_domain = "li7g.com";
      mail_smtpauth = true;
      mail_smtpname = "nextcloud@li7g.com";
      proxy = lib.mkIf config.networking.fw-proxy.enable "localhost:${toString config.networking.fw-proxy.ports.mixed}";
    };
    secretFile = config.sops.templates."nextcloud-secret-config".path;
    extraApps = {
      inherit
        (apps)
        notify_push
        onlyoffice
        memories
        previewgenerator
        maps
        ;
    };
    notify_push = {
      enable = true;
      bendDomainToLocalhost = true;
      logLevel = "info";
    };
  };
  sops.templates."nextcloud-secret-config" = {
    content = builtins.toJSON {
      mail_smtppassword = config.sops.placeholder."mail_password";
    };
    owner = "nextcloud";
  };
  environment.systemPackages = with pkgs; [
    exifRename
    ffmpeg
    exiftool
  ];
  services.nginx.virtualHosts.${cfg.hostName} = {
    forceSSL = true;
    useACMEHost = "main";
    serverName = "nextcloud.*";
  };
  services.restic.backups.b2.paths = [cfg.home];
  services.restic.backups.minio.paths = [cfg.home];

  systemd.services.nextcloud-cron.path = with pkgs; [
    perl
  ];
  systemd.services.nextcloud-notify_push = let
    nextcloudUrl = "https://nextcloud.li7g.com:${toString config.ports.https-alternative}";
  in {
    # add missing port
    postStart = lib.mkForce "${cfg.occ}/bin/nextcloud-occ notify_push:setup ${nextcloudUrl}/push";
    environment = {
      NEXTCLOUD_URL = lib.mkForce nextcloudUrl;
    };
  };
  systemd.services.nextcloud-preview-generate = {
    serviceConfig = {
      ExecStart = "${lib.getExe cfg.occ} preview:generate-all -vvv";
      ExecCondition = "${lib.getExe cfg.occ} status --exit-code";
      Type = "oneshot";
      User = "nextcloud";
      Group = "nextcloud";
    };
  };
  systemd.timers.nextcloud-preview-generate = {
    timerConfig = {
      OnCalendar = "*:0/5";
    };
    wantedBy = ["timers.target"];
  };

  sops.secrets."nextcloud_admin_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["nextcloud-setup.service"];
    owner = "nextcloud";
  };
  sops.secrets."mail_password" = {
    sopsFile = config.sops-file.get "terraform/common.yaml";
    restartUnits = ["nextcloud-setup.service"];
  };
}
