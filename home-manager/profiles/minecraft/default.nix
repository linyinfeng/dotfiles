{
  config,
  pkgs,
  lib,
  ...
}: let
  mc-li7g-com = pkgs.writeShellScriptBin "mc-li7g-com" ''
    ${pkgs.mc-config-nuc.client-launcher}/bin/minecraft \
      --gameDir "$HOME/.local/share/mc-li7g-com"
  '';
in
  lib.mkIf config.home.graphical {
    home.packages = with pkgs; [
      lunar-client
      prismlauncher
      minecraft
      mc-li7g-com
    ];

    home.global-persistence.directories = [
      ".minecraft"
      ".lunarclient"
      ".config/lunarclient"
      ".local/share/PrismLauncher"
      ".local/share/minecraft.nix"
      ".local/share/mc-li7g-com"
    ];
  }