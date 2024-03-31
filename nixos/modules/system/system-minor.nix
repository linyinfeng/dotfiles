{ config, ... }:

let
  inherit (config.system) nproc;
in
{
  systemd.slices.minor = {
    description = "Low Priority System Slice";
    sliceConfig = {
      # weights default is 100
      CPUQuota = "${toString (nproc * 90)}%";
      CPUWeight = "idle";
      IOWeight = "25";
      MemoryHigh = "80%";
      MemoryMax = "90%";
      MemorySwapMax = "80%";
    };
  };
}
