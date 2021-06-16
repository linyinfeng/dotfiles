{ ... }:

{
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    jack.enable = true;
    alsa.enable = true;
  };
  hardware.pulseaudio.enable = false;
}
