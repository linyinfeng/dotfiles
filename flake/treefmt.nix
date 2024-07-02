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
            nixfmt-rfc-style.enable = true;
            shfmt.enable = true;
            shellcheck.enable = true;
            terraform.enable = true;
            prettier.enable = true;
            stylua.enable = true;
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
