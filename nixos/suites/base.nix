{ ... }:
{
  world = {
    profiles = {
      boot = {
        kernel.latest.enable = true;
        systemd-initrd.enable = true;
      };
      development.shells.enable = true;
      global-persistence.enable = true;
      nix.auto-gen.enable = true;
      security = {
        polkit.enable = true;
        rtkit.enable = true;
        run0-sudo-shim.enable = true;
      };
      services = {
        angrr.enable = true;
        dbus.enable = true;
        openssh.enable = true;
      };
      system = {
        common.enable = true;
        constant.enable = true;
        nixos-init.enable = true;
        oomd.enable = true;
        panic.enable = true;
        perlless.enable = true;
        sysrq.enable = true;
      };
      users.root.enable = true;
    };
    suites.nixSettings.enable = true;
  };
}
