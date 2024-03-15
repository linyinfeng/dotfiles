{ config, pkgs, ... }:
let
  backupDir = "/var/lib/palworld-backup";
in
{
  systemd.services.palworld-backup = {
    script = ''
      systemctl stop palworld
      rm -rf "${backupDir}"
      cp --recursive --reflink=always "${config.services.palworld.saveDirectory}" "${backupDir}"
      systemctl start palworld
    '';
    path = with pkgs; [
      gnutar
      zstd
    ];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  services.restic.backups.minio = {
    paths = [ backupDir ];
  };
  systemd.services."restic-backups-minio" = {
    requires = [ "palworld-backup.service" ];
    after = [ "palworld-backup.service" ];
  };
}
