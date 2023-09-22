{ ... }:

{
  services.snapper.configs = {
    persist = {
      SUBVOLUME = "/persist";
      FSTYPE = "btrfs";
      SPACE_LIMIT = "0.3";
      FREE_LIMIT = "0.2";
      ALLOW_GROUPS = ["wheel"];
      TIMELINE_CREATE = true;
      TIMELINE_CLEANUP = true;
      TIMELINE_LIMIT_HOURLY = 12;
      TIMELINE_LIMIT_DAILY = 7;
      TIMELINE_LIMIT_WEEKLY = 4;
      TIMELINE_LIMIT_MONTHLY = 2;
      TIMELINE_LIMIT_YEARLY = 0;
    };
  };
}
