{ config, lib, ... }:
{
  services.avahi = {
    enable = true;
    nssmdns4 = !config.services.resolved.enable;
    nssmdns6 = !config.services.resolved.enable;
    # nixpkgs defaults the `disable-*` flags to true; publishing is opt-in here, so spell both out
    settings.publish = {
      disable-publishing = false;
      disable-user-service-publishing = false;
      publish-addresses = true;
      publish-workstation = lib.elem "workstation" config.system.types;
    };
  };
}
