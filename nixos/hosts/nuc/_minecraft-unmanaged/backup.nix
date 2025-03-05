{ pkgs, ... }:
let
  backupDir = "/var/lib/minecraft-backup";
in
{
  systemd.services.minecraft-backup = {
    script = ''
      btrfs subvolume delete "${backupDir}" || true
      btrfs subvolume snapshot -r /var/lib/minecraft "${backupDir}"
    '';
    path = with pkgs; [
      btrfs-progs
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
