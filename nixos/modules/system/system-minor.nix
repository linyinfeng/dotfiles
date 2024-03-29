{ ... }:

{
  systemd.slices.minor = {
    description = "Low Priority System Slice";
    sliceConfig = {
      # weights default is 100
      CPUWeight = "idle";
      IOWeight = "25";
    };
  };
}
