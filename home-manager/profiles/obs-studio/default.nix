{ lib, pkgs, ... }:
lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # currently nothing
    ];
  };

  home.global-persistence = {
    directories = [ ".config/obs-studio" ];
  };
}
