{
  lib,
  osConfig,
  pkgs,
  ...
}:
{
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.skim.enable = true;
  programs.zoxide.enable = true;

  programs.nushell = {
    configFile.text = ''
      $env.config.show_banner = false
    '';
    plugins = with pkgs; [
      nushell-plugin-polars
      nushell-plugin-formats # additional formats
      nushell-plugin-query # data selectors
      nushell-plugin-semver
      nushell-plugin-gstat # git status
      nushell-plugin-skim
      nushell-plugin-hcl
    ];
  };
  programs.fish.interactiveShellInit = ''
    # proxy
    ${lib.optionalString osConfig.networking.fw-proxy.enable "fenv source enable-proxy"}
  '';

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
