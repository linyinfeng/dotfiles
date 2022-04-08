{ pkgs, ... }:

{
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      hplip
    ];
  };
  # TODO python3Packages.pycurl broken
  # wait for https://nixpk.gs/pr-tracker.html?pr=166335
  services.system-config-printer.enable = false;
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
}
