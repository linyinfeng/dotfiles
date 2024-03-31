{ config, ... }:

{
  systemd.slices.minor = {
    description = "Low Priority System Slice";
    sliceConfig = {
      CPUQuota = "${toString (config.system.nproc * 80)}%";
      # weights default is 100
      CPUWeight = "idle";
      IOWeight = "25";
      MemoryHigh = "80%";
      MemoryMax = "90%";
      MemorySwapMax = "80%";
    };
  };
}
