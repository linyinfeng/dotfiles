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
      cc-switch
      llm-agents.nono
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
