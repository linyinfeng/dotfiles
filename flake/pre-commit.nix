{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    nix = ''${pkgs.nixVersions.selected}/bin/nix --experimental-features "nix-command flakes"'';
  in {
    pre-commit.check.enable = true;
    pre-commit.settings.hooks = {
      self-formatter = {
        enable = true;
        description = "The nix fmt command";
        entry = "${nix} fmt";
        pass_filenames = false;
      };
    };
    devshells.default.devshell.startup.pre-commit-hook.text =
      config.pre-commit.installationScript;
  };
}
