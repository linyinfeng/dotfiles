{
  lib,
  config,
  pkgs,
  self,
  ...
}:
let
  # the cargo setup hook forces system libraries for vendored crates, and the
  # nushell plugins carry no crate overrides of their own (NixOS/nixpkgs#585124)
  nushellPlugins = lib.mapAttrs (
    _: plugin:
    plugin.overrideAttrs (prev: {
      buildInputs = (prev.buildInputs or [ ]) ++ [
        pkgs.aws-lc
        pkgs.libgit2
        pkgs.sqlite
        pkgs.zlib
        pkgs.zstd
      ];
    })
  ) pkgs.nushellPlugins;
in
{
  programs.fish.enable = true;
  programs.nushell.enable = true;
  programs.skim.enable = true;
  programs.zoxide.enable = true;

  programs.nushell = {
    loadSessionVariables = true;
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
    plugins = with nushellPlugins; [
      polars
      formats # additional formats
      query # data selectors
      gstat # git status
      hcl
    ];
  };
  programs.fish.interactiveShellInit = ''
    # proxy
    ${lib.optionalString config.home.env.proxy.enable "fenv source enable-proxy"}
  '';
  home.packages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.fish-direnv-completions ];

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
