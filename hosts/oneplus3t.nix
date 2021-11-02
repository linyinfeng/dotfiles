{ config, pkgs, suites, profiles, lib, ... }:

let
  modem = pkgs.runCommandNoCC "oneplus3-modem" { } ''
    mkdir -p $out
    tar xf ${../binaries/oneplus3t/modem.tar.gz} -C $out
  '';
in
{
  imports =
    suites.base ++
    [
      profiles.services.pipewire # TODO sound not working
    ];

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  mobile.adbd.enable = true;

  environment.systemPackages = with pkgs; [
    htop
    lm_sensors
  ];

  hardware.firmware = [
    (config.mobile.device.firmware.override {
      inherit modem;
    })
  ];

  services.xserver.enable = true;
  # TODO gdm not working
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = false; # TODO wayland not working
  # services.xserver.displayManager.autoLogin = {
  #   enable = true;
  #   user = "yinfeng";
  # };
  services.xserver.desktopManager.xfce.enable = true;

  powerManagement.enable = true;

  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  # TODO not working
  hardware.bluetooth.enable = true;

  users.users.root.openssh.authorizedKeys.keyFiles = [
    ../users/yinfeng/ssh/id_ed25519.pub
  ];
  users.users.yinfeng = {
    uid = 1000;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = with config.users.groups; [
      users.name
      wheel.name
      keys.name
      video.name
      networkmanager.name
    ];
    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };

  # TODO kernel unsupported
  nix.useSandbox = lib.mkOverride 150 false;
}
