{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    asciinema
  ];

  home.activation.linkAsciinemaSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/asciinema"
    ln -s "/run/secrets/yinfeng-asciinema-token" "$HOME/.config/asciinema/install-id"
  '';
}
