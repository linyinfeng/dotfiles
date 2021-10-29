{ config, pkgs, suites, lib, ... }:

let
  modem = pkgs.runCommandNoCC "oneplus3-modem" { } ''
    mkdir -p $out
    tar xf ${../binaries/oneplus3t/modem.tar.gz} -C $out
  '';
in
{
  imports =
    suites.base;

  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";
  time.timeZone = "Asia/Shanghai";

  mobile.adbd.enable = true;

  # TODO not working
  mobile.quirks.qualcomm.wcnss-wlan.enable = lib.mkForce false;

  environment.systemPackages = with pkgs; [
    htop
    lm_sensors
    gnome.gnome-tweaks
  ];

  hardware.firmware = [
    (config.mobile.device.firmware.override {
      inherit modem;
    })
  ];
  passthru.modem = modem;
  passthru.firmware = config.hardware.firmware;

  services.xserver.enable = true;
  services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.displayManager.gdm.wayland = false;
  services.xserver.displayManager.autoLogin = {
    enable = true;
    user = "yinfeng";
  };
  services.xserver.desktopManager.gnome.enable = true;

  powerManagement.enable = true;
  hardware.pulseaudio.enable = true;

  networking.useDHCP = false;
  networking.networkmanager.enable = true;

  # TODO not working
  # hardware.bluetooth.enable = true;

  users.users.yinfeng = {
    uid = 1000;
    passwordFile = config.age.secrets."user-yinfeng-password".path;
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = with config.users.groups; [
      users.name
      wheel.name
      keys.name
      video.name
      networkmanager.name
    ];

    openssh.authorizedKeys.keyFiles = [
      ../users/yinfeng/ssh/id_ed25519.pub
      ../users/yinfeng/ssh/authorized-keys/t460p-win.pub
    ];
  };
  age.secrets."user-yinfeng-password".file = config.age.secrets-directory + "/user-yinfeng-password.age";

  nix.useSandbox = lib.mkOverride 150 false; # TODO kernel unsupported

  nix.binaryCaches = [ "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store" ];
}
