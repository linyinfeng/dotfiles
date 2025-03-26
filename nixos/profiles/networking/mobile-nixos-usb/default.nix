{ ... }:
{
  systemd.network.links."80-mobile-nixos-usb" = {
    matchConfig = {
      Property = [ "ID_USB_VENDOR=Mobile_NixOS" ];
    };
    linkConfig = {
      Name = "mobile0";
    };
  };
  networking.networkmanager.unmanaged = [ "mobile0" ];
  systemd.network.networks."80-mobile-nixos-usb" = {
    matchConfig = {
      Name = "mobile*";
    };
    address = [ "172.16.42.2/24" ];
    linkConfig = {
      ActivationPolicy = "bound";
    };
  };
}
