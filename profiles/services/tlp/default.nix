{ config, ... }:

{
  services.tlp = {
    enable = !config.services.power-profiles-daemon.enable;
  };
}
