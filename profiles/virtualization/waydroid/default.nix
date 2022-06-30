{ config, pkgs, lib, ... }:

{
  virtualisation.waydroid.enable = true;
  environment.etc."gbinder.d/waydroid.conf".text = lib.mkForce ''
    [Protocol]
    /dev/anbox-binder = aidl3
    /dev/anbox-vndbinder = aidl3
    /dev/anbox-hwbinder = hidl

    [ServiceManager]
    /dev/anbox-binder = aidl3
    /dev/anbox-vndbinder = aidl3
    /dev/anbox-hwbinder = hidl

    [General]
    ApiLevel = 29
  '';
  environment.global-persistence.user.directories = [
    ".local/share/waydroid"
  ];
}
