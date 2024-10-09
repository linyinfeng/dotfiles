{
  config,
  pkgs,
  lib,
  ...
}:
let
  version = 30; # pinned

  cfg = config.services.nextcloud;
  package = pkgs."nextcloud${toString version}";
  inherit (package.packages) apps;

  exifRename = pkgs.writeShellApplication {
    name = "exif-rename";
    runtimeInputs = with pkgs; [ exiftool ];
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

  processInstantUploadUnwrapped = pkgs.writeShellApplication {
    name = "nextcloud-process-instant-upload-unwrapped";
    runtimeInputs = [
      cfg.occ
      exifRename
      pkgs.perl
    ];
    text = ''
      username="$1"

      user_files_dir="${cfg.datadir}/data/$username/files"
      pushd "$user_files_dir/Camera"
      exif-rename -v "InstantUpload"
      popd

      nextcloud-occ files:scan "$username"
      nextcloud-occ memories:index --user="$username"
      nextcloud-occ preview:generate-all --path="$username/files"
    '';
  };

  processInstantUpload = pkgs.writeShellApplication {
    name = "nextcloud-process-instant-upload";
    runtimeInputs = [
      processInstantUploadUnwrapped
      "/run/wrappers" # for sudo
    ];
    text = ''
      run="exec"
      if [[ "$USER" != nextcloud ]]; then
        run="exec sudo --user=nextcloud"
      fi
      $run nextcloud-process-instant-upload-unwrapped "$@"
    '';
  };
in
{
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
    };
    settings = {
      trusted_domains = [
        "nextcloud.ts.li7g.com"
        "nextcloud.dn42.li7g.com"
      ];
      default_phone_region = "CN";
      mail_smtpmode = "smtp";
      mail_smtphost = "smtp.ts.li7g.com";
      mail_smtpport = config.ports.smtp-starttls;
      mail_from_address = "nextcloud";
      mail_domain = "li7g.com";
      mail_smtpauth = true;
      mail_smtpname = "nextcloud@li7g.com";
      proxy = lib.mkIf config.networking.fw-proxy.enable "localhost:${toString config.networking.fw-proxy.ports.mixed}";
      # https://docs.nextcloud.com/server/latest/admin_manual/configuration_server/config_sample_php_parameters.html#enabledpreviewproviders
      enabledPreviewProviders = [
        # double slash to escape

        # default endabled providers
        "OC\\Preview\\BMP"
        "OC\\Preview\\GIF"
        "OC\\Preview\\JPEG"
        "OC\\Preview\\Krita"
        "OC\\Preview\\MarkDown"
        "OC\\Preview\\MP3"
        "OC\\Preview\\OpenDocument"
        "OC\\Preview\\PNG"
        "OC\\Preview\\TXT"
        "OC\\Preview\\XBitmap"

        # additional providers
        "OC\\Preview\\Image"
        "OC\\Preview\\HEIC"
        "OC\\Preview\\TIFF"
        "OC\\Preview\\Movie"
      ];

      # memories
      "memories.vod.disable" = false; # enable video transcoding
      "memories.vod.vaapi" = true;
    };
    secretFile = config.sops.templates."nextcloud-secret-config".path;
    extraApps = {
      inherit (apps)
        notify_push
        onlyoffice
        memories
        previewgenerator
        # maps # TODO wait for support on nextcloud 30
        ;
    };
    notify_push = {
      enable = true;
      bendDomainToLocalhost = true;
      logLevel = "info";
    };
  };
  sops.templates."nextcloud-secret-config" = {
    content = builtins.toJSON { mail_smtppassword = config.sops.placeholder."mail_password"; };
    owner = "nextcloud";
  };
  environment.systemPackages = with pkgs; [
    exifRename
    processInstantUpload
    ffmpeg
    exiftool
  ];
  services.nginx.virtualHosts.${cfg.hostName} = {
    forceSSL = true;
    inherit (config.security.acme.tfCerts."li7g_com".nginxSettings) sslCertificate sslCertificateKey;
    serverName = "nextcloud.*";
  };
  services.restic.backups.b2.paths = [ cfg.home ];

  systemd.services.nextcloud-cron.path = with pkgs; [ perl ];
  systemd.services.nextcloud-notify_push =
    let
      nextcloudUrl = "https://nextcloud.li7g.com:${toString config.ports.https-alternative}";
    in
    {
      # add missing port
      postStart = lib.mkForce "${cfg.occ}/bin/nextcloud-occ notify_push:setup ${nextcloudUrl}/push";
      environment = {
        NEXTCLOUD_URL = lib.mkForce nextcloudUrl;
      };
    };
  systemd.services.phpfpm-nextcloud.serviceConfig = {
    # allow access to VA-API device
    PrivateDevices = lib.mkForce false;
  };

  systemd.services.nextcloud-cron-extra = {
    script = ''
      nextcloud-occ preview:pre-generate
    '';
    serviceConfig = {
      ExecCondition = "${lib.getExe cfg.occ} status --exit-code";
      Type = "oneshot";
      User = "nextcloud";
      Group = "nextcloud";
    };
    path = [ cfg.occ ];
  };
  systemd.timers.nextcloud-cron-extra = {
    timerConfig = {
      OnCalendar = "*:0/5";
    };
    wantedBy = [ "timers.target" ];
  };

  systemd.services.nextcloud-cron-daily = {
    script = ''
      nextcloud-process-instant-upload yinfeng
    '';
    serviceConfig = {
      ExecCondition = "${lib.getExe cfg.occ} status --exit-code";
      Type = "oneshot";
      User = "nextcloud";
      Group = "nextcloud";
    };
    path = [ processInstantUpload ];
  };
  systemd.timers.nextcloud-cron-daily = {
    timerConfig = {
      OnCalendar = "02:00";
    };
    wantedBy = [ "timers.target" ];
  };

  sops.secrets."nextcloud_admin_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "nextcloud-setup.service" ];
    owner = "nextcloud";
  };
  sops.secrets."mail_password" = {
    terraformOutput.enable = true;
    restartUnits = [ "nextcloud-setup.service" ];
  };
}
