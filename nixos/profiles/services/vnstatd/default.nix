{ config, ... }:
{
  services.vnstat.enable = true;
  systemd.services.vnstat.restartTriggers = [ config.environment.etc."vnstat.conf".text ];
  environment.etc."vnstat.conf".text = ''
    UseUTC 1
  '';
}
