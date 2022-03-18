{ ... }:

let
  backupOnCalendar = "01:30:00";
  backupRoot = "/media/data/backup";
in
{
  services.postgresqlBackup = {
    enable = true;
    backupAll = true;
    compression = "zstd";
    location = "${backupRoot}/postgresql";
    startAt = backupOnCalendar;
  };

  systemd.services.vaultwarden-backup = {
    script = ''
      DATA_DIR="/var/lib/bitwarden_rs"
      BACKUP_DIR="${backupRoot}/vaultwarden"
      mkdir -p "${backupRoot}/vaultwarden"
      cp -r "$DATA_DIR/attachments" "$BACKUP_DIR"
      cp -r "$DATA_DIR"/rsa_key.* "$BACKUP_DIR"
    '';
    serviceConfig.Type = "oneshot";
  };
  systemd.timers.vaultwarden-backup = {
    timerConfig.OnCalendar = backupOnCalendar;
    wantedBy = [ "timers.target" ];
  };
}
