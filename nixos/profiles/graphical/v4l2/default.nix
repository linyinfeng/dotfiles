{
  config,
  pkgs,
  ...
}: {
  boot.extraModulePackages = [
    config.boot.kernelPackages.v4l2loopback
  ];
  boot.kernelModules = [
    "v4l2loopback"
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 card_label="V4L2 Loopback"
  '';
  environment.systemPackages = [
    pkgs.v4l-utils
    config.boot.kernelPackages.v4l2loopback.bin
  ];
}
