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
      nono

      claude-code
      antigravity-cli
      codex
      pi-coding-agent
    ]
    ++ (lib.optional (!config.programs.opencode.enable) pkgs.opencode);

  home.global-persistence.directories = [
    ".cc-switch"
    ".codex"
    ".claude"
    ".gemini"
    ".continue"
    ".codebuddy"
    ".config/reasonix"
    ".config/kilo"
    ".config/mimocode"
    ".local/share/mimocode"
    ".config/opencode"
    ".local/share/opencode"
    ".cache/opencode"
    ".pi"
  ];
  home.global-persistence.files = [
    ".claude.json"
  ];
}
