{ pkgs, ... }:
let
  backupDir = "/var/lib/minecraft-backup";
in
{
  systemd.services.minecraft-backup = {
    script = ''
      rm -rf "${backupDir}"
      cp --recursive --reflink=always /var/lib/minecraft "${backupDir}"
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
    requires = [ "minecraft-backup.service" ];
    after = [ "minecraft-backup.service" ];
  };
}
