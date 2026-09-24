{ lib, ... }:
{
  world.suites.nixSettings.enable = lib.mkDefault true;

  world.profiles.boot.kernel.latest.enable = lib.mkDefault true;
  world.profiles.boot.systemd-initrd.enable = lib.mkDefault true;
  world.profiles.services.openssh.enable = lib.mkDefault true;
  world.profiles.services.dbus.enable = lib.mkDefault true;
  world.profiles.services.angrr.enable = lib.mkDefault true;
  world.profiles.security.polkit.enable = lib.mkDefault true;
  world.profiles.security.rtkit.enable = lib.mkDefault true;
  world.profiles.security.run0-sudo-shim.enable = lib.mkDefault true;
  world.profiles.global-persistence.enable = lib.mkDefault true;
  world.profiles.system.constant.enable = lib.mkDefault true;
  world.profiles.system.common.enable = lib.mkDefault true;
  world.profiles.system.sysrq.enable = lib.mkDefault true;
  world.profiles.system.perlless.enable = lib.mkDefault true;
  world.profiles.system.nixos-init.enable = lib.mkDefault true;
  world.profiles.system.oomd.enable = lib.mkDefault true;
  world.profiles.system.panic.enable = lib.mkDefault true;
  world.profiles.development.shells.enable = lib.mkDefault true;
  world.profiles.users.root.enable = lib.mkDefault true;
}
