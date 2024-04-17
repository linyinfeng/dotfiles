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
          };
          settings.formatter.prettier = {
            excludes = [
              # no need to format generated secrets files
              "secrets/**/*.yaml"
            ];
          };
        };
      })
      (lib.mkIf (!config.isDevSystem) { treefmt.flakeCheck = false; })
    ];
}
