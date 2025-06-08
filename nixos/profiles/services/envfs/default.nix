{ ... }:
{
  services.envfs.enable = true;

  # systemd requires `/usr` being properly populated before switching root
  # envfs disables the "population" of `/usr/bin/env`
  # "populate" an non-empty `/usr` to make systemd happy
  boot.initrd.systemd.services.ensure-usr = {
    script = ''
      mkdir --parents --verbose /sysroot/usr/bin
    '';
    before = [ "initrd-fs.target" ];
    requiredBy = [ "initrd-fs.target" ];
  };
}
