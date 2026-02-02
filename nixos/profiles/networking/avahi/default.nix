{ config, lib, ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = !config.services.resolved.enable;
    nssmdns6 = !config.services.resolved.enable;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
      workstation = lib.elem "workstation" config.system.types;
    };
  };
}
