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
    path = with pkgs; [
      gnutar
      zstd
    ];
    serviceConfig = {
      Type = "oneshot";
    };
  };

  services.restic.backups.garage = {
    paths = [ backupDir ];
  };
  systemd.services."restic-backups-garage" = {
    requires = [ "minecraft-backup.service" ];
    after = [ "minecraft-backup.service" ];
  };
}
