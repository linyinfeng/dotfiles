{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # currently nothing
    ];
  };

  xdg.desktopEntries.obs-studio-wayland = {
    name = "OBS Studio (Wayland)";
    genericName = "Streaming/Recording Software";
    exec = "env QT_QPA_PLATFORM=wayland obs";
    icon = "com.obsproject.Studio";
    terminal = false;
    type = "Application";
    categories = [
      "AudioVideo"
      "Recorder"
    ];
    settings = {
      "StartupWMClass" = "obs";
    };
    startupNotify = true;
  };

  home.global-persistence = {
    directories = [ ".config/obs-studio" ];
  };
}
