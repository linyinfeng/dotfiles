{ pkgs, ... }:
{
  # The Atom68 EC keymap lives next to this file in _atom68-ec-keymap.json. Push it back with
  # `nizctl push < _atom68-ec-keymap.json`, after pressing Fn + the top-right key: the keymap
  # only applies in the keyboard's Program mode, OFFICE mode keeps the factory layout.
  services.udev.extraRules = ''
    # Atom68 EC (68EC-S); nizctl goes through hidapi's libusb backend, so it opens the usb
    # device node rather than hidraw.
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="5132", MODE="0660", GROUP="plugdev", TAG+="uaccess"
  '';
  environment.systemPackages = [ pkgs.nizctl ];
}
