{ pkgs, ... }:

let
  backupDir = "/var/lib/minecraft-backup";
in
{
  systemd.services.minecraft-backup = {
    script = ''
      systemctl stop  minecraft
      rm -rf "${backupDir}"
      cp --recursive --reflink=always /var/lib/private/minecraft "${backupDir}"
      systemctl start minecraft
    '';
    path = with pkgs; [ gnutar zstd ];
    serviceConfig = {
      type = "oneshot";
    };
  };

  services.restic.backups.minio = {
    paths = [
      backupDir
    ];
  };
  systemd.services."restic-backups-minio" = {
    requires = [ "minecraft-backup.service" ];
    after = [ "minecraft-backup.service" ];
  };
}
