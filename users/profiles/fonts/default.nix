{ config, lib, ... }:

lib.mkIf config.home.graphical {
  home.global-persistence.directories = [
    ".local/share/fonts"
  ];
}
