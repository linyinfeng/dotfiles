{ pkgs, ... }:
let
  mc-li7g-com = pkgs.writeShellScriptBin "mc-li7g-com" ''
    ${pkgs.mc-config-nuc.minecraft-default-client}/bin/minecraft \
      --gameDir "$HOME/.local/share/mc-li7g-com"
  '';
in
{
  home.packages = with pkgs; [
    # lunar-client
    # minecraft
    # prismlauncher
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
