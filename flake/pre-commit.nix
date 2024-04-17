{ ... }:
{
  perSystem =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    lib.mkMerge [
      (lib.mkIf config.isDevSystem {
        pre-commit.settings.hooks = {
          actionlint.enable = true;
          check-json.enable = true;
          check-added-large-files.enable = true;
          check-yaml.enable = true;
          checkmake.enable = true;
          markdownlint.enable = true;

          flake-treefmt = {
            enable = true;
            name = "flake-treefmt";
            # also include .github explicitly
            entry = "${config.treefmt.build.wrapper}/bin/treefmt . .github";
            pass_filenames = false;
          };
        };
        devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
      })
      (lib.mkIf (!config.isDevSystem) { pre-commit.check.enable = false; })
    ];
}
