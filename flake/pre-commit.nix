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
        pre-commit.check.enable = true;
        pre-commit.settings.hooks = {
          # currently nothing
        };
        devshells.default.devshell.startup.pre-commit-hook.text = config.pre-commit.installationScript;
      })
      (lib.mkIf (!config.isDevSystem) { pre-commit.check.enable = false; })
    ];
}
