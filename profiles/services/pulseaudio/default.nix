{ ... }:

{
  hardware.pulseaudio.enable = true;

  environment.global-persistence.user.directories = [
    ".config/pulse"
  ];
}
