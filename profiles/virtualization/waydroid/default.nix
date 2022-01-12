{ config, pkgs, lib, ... }:

{
  virtualisation.waydroid.enable = true;
  environment.etc."gbinder.d/waydroid.conf".text = lib.mkForce ''
    [Protocol]
    /dev/binder = aidl3
    /dev/vndbinder = aidl3
    /dev/hwbinder = hidl

    [ServiceManager]
    /dev/binder = aidl3
    /dev/vndbinder = aidl3
    /dev/hwbinder = hidl

    [General]
    ApiLevel = 30
  '';
  # system.activationScripts.setupBinderLinks = {
  #   deps = [ "users" "groups" ];
  #   text = ''
  #     binders=(binder vndbinder hwbinder)
  #     for b in "''${binders[@]}"; do
  #       ln -sf /dev/anbox-$b /dev/$b
  #       chmod 666 /dev/$b
  #     done
  #   '';
  # };
  environment.global-persistence.user.directories = [
    ".local/share/waydroid"
  ];
}
