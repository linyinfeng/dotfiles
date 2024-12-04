{ ... }:
{
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      treefmtWrapper = pkgs.writeShellScriptBin "treefmt" ''
        unset PRJ_ROOT
        exec "${lib.getExe config.treefmt.build.wrapper}" "$@"
      '';
    in
    lib.mkMerge [
      {
        treefmt = {
          flakeFormatter = config.isDevSystem;
          flakeCheck = config.isDevSystem;
        };
      }
      (lib.mkIf config.isDevSystem {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            statix = {
              enable = true;
              disabled-lints = [ "empty_pattern" ];
            };
            deadnix.enable = true;
            shfmt.enable = true;
            shellcheck.enable = true;
            terraform.enable = true;
            prettier.enable = true;
            stylua.enable = true;
            keep-sorted.enable = true;
          };
          settings.formatter = {
            shfmt = {
              includes = [
                ".envrc"
                "**/.envrc"
              ];
            };
            shellcheck = {
              includes = [
                ".envrc"
                "**/.envrc"
              ];
            };
            keep-sorted = {
              includes = lib.mkForce [ "*.nix" ];
            };
          };
        };
        devshells.default.commands = [
          # treefmt defaults --tree-root from $PRJ_ROOT
          {
            category = "misc";
            package = treefmtWrapper;
          }
        ];
        pre-commit.settings.hooks = {
          flake-treefmt = {
            enable = true;
            name = "flake-treefmt";
            entry = lib.getExe treefmtWrapper;
            pass_filenames = false;
          };
        };
      })
      (lib.mkIf (!config.isDevSystem) { treefmt.flakeCheck = false; })
    ];
}
