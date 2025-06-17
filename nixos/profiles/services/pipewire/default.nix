{ pkgs, lib, ... }:
{
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;

    audio.enable = lib.mkDefault true;

    # emulations
    pulse.enable = lib.mkDefault true;
    jack.enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
  };
  services.pulseaudio.enable = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    helvum
    easyeffects
  ];
  environment.global-persistence.user.directories = [
    ".local/state/wireplumber"
    ".config/easyeffects"
  ];
}
