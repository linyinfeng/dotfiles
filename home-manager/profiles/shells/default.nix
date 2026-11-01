{
  lib,
  config,
  pkgs,
  ...
}:
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
    plugins = with pkgs.nushellPlugins; [
      polars
      formats # additional formats
      query # data selectors
      gstat # git status
      hcl
    ];
  };
  programs.fish.interactiveShellInit = ''
    # direnv changes XDG_DATA_DIRS after Fish has initialized its search paths.
    function __update_direnv_completions --on-variable XDG_DATA_DIRS
      for directory in $__direnv_completion_dirs
        set -l index (contains --index -- $directory $fish_complete_path)
        if test -n "$index"
          set -e fish_complete_path[$index]
        end
      end
      set -g __direnv_completion_dirs
      for directory in (string split : -- $XDG_DATA_DIRS)
        set -l completions "$directory/fish/vendor_completions.d"
        if test -d "$completions"; and not contains -- $completions $fish_complete_path
          set -ga __direnv_completion_dirs $completions
        end
      end
      set -p fish_complete_path $__direnv_completion_dirs
    end
    __update_direnv_completions

    # proxy
    ${lib.optionalString config.home.env.proxy.enable "fenv source enable-proxy"}
  '';

  home.global-persistence.directories = [
    ".local/share/zoxide"
    ".local/share/direnv"
  ];
}
