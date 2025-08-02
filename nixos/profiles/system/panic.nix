{ ... }:
{
  boot.kernelParams = [
    "panic=60" # auto reboot at 1 minites after kernel panics
    "drm.panic_screen=qr_code"
  ];
}
