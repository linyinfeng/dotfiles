{...}: {
  perSystem = {
    config,
    pkgs,
    ...
  }: let
    nix = "${pkgs.nixVersions.selected}/bin/nix";
  in {
    pre-commit.settings.hooks = {
      self-formatter = {
        enable = true;
        description = "The nix fmt command";
        entry = "${nix} fmt";
        pass_filenames = false;
      };
      show = {
        enable = true;
        description = "The nix flake show command";
        entry = "${nix} flake show";
        pass_filenames = false;
      };
      check-no-build = {
        enable = true;
        description = "The nix flake check --no-build command";
        entry = "${nix} flake check --no-build";
        pass_filenames = false;
      };
    };
    devshells.default.devshell.startup.pre-commit-hook.text =
      config.pre-commit.installationScript;
  };
}
