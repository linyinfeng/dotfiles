{ ... }:
{
  services.envfs.enable = true;
  fileSystems."/usr/bin".options = [
    "x-systemd.requires=modprobe@fuse.service"
    "x-systemd.after=modprobe@fuse.service"
  ];
  # TODO upstream
  # /bin will be canonicalized to /usr/bin
  # Jun 09 02:46:50 parrot systemd-fstab-generator[472]: Found entry what=none where=/usr/bin type=envfs makefs=no growfs=no pcrfs=no noauto=no nofail=yes
  # Jun 09 02:46:50 parrot systemd-fstab-generator[472]: Canonicalized where=/bin to /usr/bin
  # Jun 09 02:46:50 parrot systemd-fstab-generator[472]: Found entry what=/usr/bin where=/usr/bin type=none makefs=no growfs=no pcrfs=no noauto=no nofail=yes
  # Jun 09 02:46:50 parrot systemd-fstab-generator[472]: Failed to create unit file '/run/systemd/generator/usr-bin.mount', as it already exists. Duplicate entry in '/etc/fstab'?
  fileSystems."/bin".enable = false;

  # systemd requires `/usr` being properly populated before switching root
  # envfs disables the "population" of `/usr/bin/env`
  # "populate" an non-empty `/usr` to make systemd happy
  boot.initrd.systemd.tmpfiles.settings = {
    "50-usr-bin" = {
      "/sysroot/usr/bin" = {
        d = {
          group = "root";
          mode = "0755";
          user = "root";
        };
      };
    };
  };
}
