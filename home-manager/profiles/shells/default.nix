{ lib, osConfig, ... }:
{
  programs.fish.enable = true;
  programs.skim.enable = true;
  programs.zoxide.enable = true;

  programs.fish.interactiveShellInit = ''
    # proxy
    ${lib.optionalString osConfig.networking.fw-proxy.enable "fenv source enable-proxy"}
  '';

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
