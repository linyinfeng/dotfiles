{ ... }:
{
  systemd.targets.graphical-powersave = {
    requires = [ "graphical.target" ];
    after = [ "graphical.target" ];
    conflicts = [
      "cowrie.service"
      "telegraf.service"
      "promtail.service"
      "tailscaled.service"
      "zerotierone.service"
      "container@syncthing-yinfeng.service"
    ];
    unitConfig = {
      AllowIsolate = true;
    };
  };
}
