{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    asciinema
  ];

  # home.activation.linkAsciinemaSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   mkdir -p "$HOME/.config/asciinema"
  #   ln -sf "/run/secrets/yinfeng-asciinema-token" "$HOME/.config/asciinema/install-id"
  # '';
  home.linkSecrets.".config/asciinema/install-id".secret =
    config.passthrough.systemConfig.age.secrets.yinfeng-asciinema-token.path;
}
