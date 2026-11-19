{ ... }:
{
  perSystem =
    { config, lib, ... }:
    lib.mkMerge [
      (lib.mkIf config.isDevSystem {
        pre-commit.settings.hooks = {
          actionlint = {
            enable = true;
            # TODO Remove this ignore once actionlint ships support for concurrency.queue.
            # https://github.com/rhysd/actionlint/issues/657
            # https://github.com/rhysd/actionlint/pull/654
            args = [
              "-ignore"
              ''^unexpected key "queue" for "concurrency" section\.''
            ];
          };
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
