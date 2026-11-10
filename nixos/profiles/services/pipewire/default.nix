{ pkgs, lib, ... }:
{
  services.pipewire = {
    enable = true;
    wireplumber.enable = true;

    audio.enable = lib.mkDefault true;

    # emulations
    pulse.enable = lib.mkDefault true;
    alsa.enable = lib.mkDefault true;
  };
  services.pulseaudio.enable = lib.mkDefault false;

  environment.systemPackages = with pkgs; [
    crosspipe
    # jack emulation is impure since nixpkgs dropped the global LD_LIBRARY_PATH;
    # jack clients start through `pw-jack <app>`
    pipewire.jack
    # easyeffects # TODO broken in aarch64-linux
  ];
  environment.global-persistence.user.directories = [
    ".local/state/wireplumber"
    ".config/easyeffects"
    ".local/share/easyeffects"
  ];
}
