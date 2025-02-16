{ ... }:
{
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      # web features
      "--enable-experimental-web-platform-features"

      # wayland
      "--ozone-platform-hint=auto"

      # input method
      "--enable-wayland-ime"
      "--wayland-text-input-version=3"

      # video acceleration
      "--enable-features=AcceleratedVideoDecodeLinuxGL"
    ];
  };

  home.global-persistence.directories = [ ".config/chromium" ];

  home.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };
}
