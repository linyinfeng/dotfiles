{...}: {
  systemd.targets.graphical-powersave = {
    bindsTo = ["graphical.target"];
    conflicts = [
      "cowrie.service"
      "telegraf.service"
      "promtail.service"
      "container@syncthing-yinfeng.service"
    ];
    unitConfig = {
      AllowIsolate = true;
    };
  };
}
