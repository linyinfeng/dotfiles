{ ... }:
{
  perSystem =
    { config, lib, ... }:
    lib.mkMerge [
      (lib.mkIf config.isDevSystem {
        pre-commit.settings.hooks = {
          actionlint.enable = true;
          check-json.enable = true;
          check-added-large-files.enable = true;
          check-yaml.enable = true;
          checkmake.enable = true;
          markdownlint.enable = true;
        };
        devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
      })
      (lib.mkIf (!config.isDevSystem) { pre-commit.check.enable = false; })
    ];
}
