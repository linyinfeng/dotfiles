{ config, lib, ... }:

{
  services.avahi = {
    enable = true;
    nssmdns = true;
  };
}
