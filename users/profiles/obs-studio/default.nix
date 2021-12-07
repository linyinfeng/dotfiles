{ pkgs, ... }:

{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # wlrobs
    ];
  };

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
  };

  home.global-persistence = {
    directories = [
      ".config/obs-studio"
    ];
  };
}
