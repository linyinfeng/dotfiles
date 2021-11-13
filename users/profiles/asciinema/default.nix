{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    asciinema
  ];

  home.link.".config/asciinema/install-id".target =
    config.passthrough.systemConfig.sops.secrets."yinfeng/asciinema-token".path;
}
