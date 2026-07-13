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

      # Direnv
      use std/config env-conversions
      # Initialize the PWD hook as an empty list if it doesn't exist
      $env.config.hooks.env_change.PWD = $env.config.hooks.env_change.PWD? | default []
      $env.config.hooks.env_change.PWD ++= [{||
        if (which direnv | is-empty) {
          # If direnv isn't installed, do nothing
          return
        }

        direnv export json | from json | default {} | load-env
        # If direnv changes the PATH, it will become a string and we need to re-convert it to a list
        $env.PATH = do (env-conversions).path.from_string $env.PATH
      }]
    '';
    plugins = with pkgs; [
      nushell-plugin-polars
      nushell-plugin-formats # additional formats
      nushell-plugin-query # data selectors
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
