{ ... }:
{
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkMerge [
      (lib.mkIf config.isDevSystem {
        treefmt = {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            statix = {
              enable = true;
              disabled-lints = [ "empty_pattern" ];
            };
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
          {
            category = "misc";
            package = config.treefmt.build.wrapper;
          }
        ];
      })
      (lib.mkIf (!config.isDevSystem) { treefmt.flakeCheck = false; })
    ];
}
