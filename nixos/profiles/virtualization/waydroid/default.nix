{ lib, ... }:
{
  virtualisation.waydroid.enable = true;
  environment.etc."gbinder.d/waydroid.conf".text = lib.mkForce ''
    [General]
    ApiLevel = 30
  '';
  environment.global-persistence.user.directories = [ ".local/share/waydroid" ];
}
