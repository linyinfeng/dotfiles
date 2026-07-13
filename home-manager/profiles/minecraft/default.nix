{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # lunar-client
    # minecraft
    prismlauncher
    hmcl
    # mc-li7g-com
  ];

  home.global-persistence.directories = [
    ".minecraft"
    ".lunarclient"
    ".hmcl"
    ".config/lunarclient"
    ".local/share/PrismLauncher"
    ".local/share/minecraft.nix"
    ".local/share/mc-li7g-com"
  ];
}
