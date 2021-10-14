{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    asciinema
  ];

  # home.activation.linkAsciinemaSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   mkdir -p "$HOME/.config/asciinema"
  #   ln -sf "/run/secrets/yinfeng-asciinema-token" "$HOME/.config/asciinema/install-id"
  # '';
  home.link.".config/asciinema/install-id".target =
    config.passthrough.systemConfig.age.secrets.yinfeng-asciinema-token.path;
}
