{ pkgs, ... }:

{
  home.packages = with pkgs; [
    asciinema
  ];

  xdg.configFile."asciinema/install-id".source = ../../../secrets/asciinema/recorder-token.txt;
}
