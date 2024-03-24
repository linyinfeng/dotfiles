{ ... }:

{
  systemd.slices.system-minor = {
    description = "Low Priority System Slice";

    sliceConfig = {
      # weights default is 100
      CPUWeight = "25";
      IOWeight = "25";
    };
  };
}
