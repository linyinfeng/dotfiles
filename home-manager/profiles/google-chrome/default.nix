{ ... }:
{
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      # web features
      "--enable-experimental-web-platform-features"

      # video acceleration
      "--enable-features=AcceleratedVideoDecodeLinuxGL"
    ];
  };

  home.global-persistence.directories = [ ".config/google-chrome" ];
}
