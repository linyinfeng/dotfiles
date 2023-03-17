{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    pre-commit.settings.hooks.nix-fmt = {
      enable = true;
      description = "nix fmt";
      entry = "${pkgs.nixVersions.selected}/bin/nix fmt";
    };
    devshells.default.devshell.startup.pre-commit-hook.text =
      config.pre-commit.installationScript;
  };
}
