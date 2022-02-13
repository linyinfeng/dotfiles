{ pkgs, ... }:

{
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;
    media-session.enable = false;

    # emulations
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
  };
  hardware.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    helvum
    easyeffects
  ];
  environment.global-persistence.user.directories = [
    ".config/easyeffects"
  ];
}
