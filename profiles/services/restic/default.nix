{ config, pkgs, lib, ... }:

let
  defaultTimerConfig = {
    OnCalendar = "03:00:00";
    RandomizedDelaySec = "30min";
  };
  cfgB2 = {
    repository = "b2:yinfeng-backup";
    environmentFile = config.sops.templates."restic-b2-env".path;
    passwordFile = config.sops.secrets."restic/password".path;
  };
  cfgMinio = {
    repository = "s3:https://minio.li7g.com/backup";
    environmentFile = config.sops.templates."restic-minio-env".path;
    passwordFile = config.sops.secrets."restic/password".path;
  };

  mkScript = cfg: pkgs.substituteAll ({
    src = ./wrapper.sh;
    isExecutable = true;
    inherit (pkgs) restic;
  } // cfg);
  mkServiceCfg = cfg: {
    initialize = true;
    timerConfig = lib.mkDefault defaultTimerConfig;
  } // cfg;

  scripts = pkgs.stdenvNoCC.mkDerivation {
    name = "restic-scripts";
    buildCommand = ''
      install -Dm755 $resticB2    $out/bin/restic-b2
      install -Dm755 $resticMinio $out/bin/restic-minio
    '';
    resticB2 = mkScript cfgB2;
    resticMinio = mkScript cfgMinio;
  };
in
{
  services.restic.backups.b2 = mkServiceCfg cfgB2;
  services.restic.backups.minio = mkServiceCfg cfgMinio;

  sops.templates."restic-b2-env".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder."backup-b2/key-id"}"
    B2_ACCOUNT_KEY="${config.sops.placeholder."backup-b2/access-key"}"
  '';
  sops.templates."restic-minio-env".content = ''
    AWS_ACCESS_KEY_ID="${config.sops.placeholder."backup-minio/key-id"}"
    AWS_SECRET_ACCESS_KEY="${config.sops.placeholder."backup-minio/access-key"}"
  '';
  sops.secrets."restic/password".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-b2/access-key".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-b2/key-id".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-minio/access-key".sopsFile = config.sops.secretsDir + /common.yaml;
  sops.secrets."backup-minio/key-id".sopsFile = config.sops.secretsDir + /common.yaml;

  environment.systemPackages = [
    scripts
  ];
}
