{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Fabric's default full code mode hides Pi's core tools behind `fabric_exec`;
  # the env override is its orchestration-only mode. `pi-args` land after the
  # adapter's own flags, so `pi` has to be a wrapper rather than `env`.
  pi = pkgs.writeShellScriptBin "pi-command-not-found" ''
    export PI_FABRIC_FULL_CODE_MODE=false
    exec ${lib.getExe config.programs.pi-coding-agent.package} "$@"
  '';
in
{
  programs.pi-command-not-found-adapter = {
    enable = true;
    model = "deepseek/deepseek-flash";
    pi = lib.getExe pi;
  };

  # the adapter's pi sessions and the notes they keep
  home.global-persistence.directories = [
    ".local/state/pi-command-not-found-adapter"
  ];
}
