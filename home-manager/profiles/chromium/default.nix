{ ... }:
{
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      "--enable-experimental-web-platform-features"
      "--ozone-platform-hint=auto"
      "--enable-wayland-ime"
      "--wayland-text-input-version=3" # wait for chromium 129
    ];
  };

  home.global-persistence.directories = [ ".config/chromium" ];

  home.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };
}
