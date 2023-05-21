{
  config,
  lib,
  ...
}:
lib.mkIf config.home.graphical {
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      # TODO disabled
      # ibus not working
      # "--ozone-platform-hint=auto"
      # "--enable-wayland-ime" # text-input-v1, only works in hyprland
      # "--gtk-version=4"
    ];
  };

  home.global-persistence.directories = [
    ".config/chromium"
  ];

  home.sessionVariables = {
    GOOGLE_DEFAULT_CLIENT_ID = "77185425430.apps.googleusercontent.com";
    GOOGLE_DEFAULT_CLIENT_SECRET = "OTJgUOQcT7lO7GsGZq2G4IlT";
  };
}
