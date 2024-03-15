{ pkgs, ... }:
{
  services.udev.extraRules = ''
    # Taken from https://wiki.archlinux.org/title/backlight
    # uaccess, GROUP and MODE does not work for sysfs
    # https://github.com/systemd/systemd/issues/5746
    # https://wiki.archlinux.org/title/Talk:Backlight#Udev_rules_for_permissions_of_brightness_doesn't_work
    ACTION=="add", SUBSYSTEM=="backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
    ACTION=="add", SUBSYSTEM=="leds", \
      RUN+="${pkgs.coreutils}/bin/chgrp video $sys$devpath/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w $sys$devpath/brightness"
  '';
}
