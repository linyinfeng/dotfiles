{
  config,
  pkgs,
  lib,
  ...
}:
let
  subvolumes = lib.lists.map (v: v.SUBVOLUME) (lib.attrValues config.services.snapper.configs);
  createForSubvolume =
    subvol:
    let
      target = "${subvol}/.snapshots";
    in
    ''
      if [ ! -e "${target}" ]; then
        btrfs subvolume create "${target}"
      fi
    '';
in
{
  services.snapper.configs = {
    persist = {
      SUBVOLUME = "/persist";
      FSTYPE = "btrfs";
      SPACE_LIMIT = "0.3";
      FREE_LIMIT = "0.2";
      ALLOW_GROUPS = [ "wheel" ];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 12;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 2;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };
  systemd.services.snapper-subvolumes = {
    script = lib.concatMapStringsSep "\n" createForSubvolume subvolumes;
    serviceConfig = {
      Type = "oneshot";
    };
    path = with pkgs; [ btrfs-progs ];
    requiredBy = [ "snapper-timeline.service" ];
    before = [ "snapper-timeline.service" ];
  };
}
