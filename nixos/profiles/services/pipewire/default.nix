{pkgs, ...}: {
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;

    # emulations
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
  };
  hardware.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    # helvum # TODO borken
    easyeffects
  ];
  environment.global-persistence.user.directories = [
    ".local/state/wireplumber"
    ".config/easyeffects"
  ];
}
