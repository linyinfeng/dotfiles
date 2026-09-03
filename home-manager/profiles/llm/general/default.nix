{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./_mcp.nix
  ];
  home.packages =
    with pkgs;
    [
      llm-agents.nono
      llm-agents.cc-switch-cli
      codex
    ]
    ++ (lib.optional (!config.programs.opencode.enable) pkgs.opencode);

  home.global-persistence.directories = [
    ".cc-switch"
    ".codex"
    ".continue"
    ".codebuddy"
    ".config/opencode"
    ".local/share/opencode"
    ".cache/opencode"
  ];
}
