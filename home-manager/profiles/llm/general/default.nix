{
  pkgs,
  ...
}:
{
  imports = [
    ./_mcp.nix
  ];
  home.packages = [
    pkgs.cc-switch
    pkgs.nono

    pkgs.claude-code
    pkgs.antigravity-cli
    pkgs.codex
    pkgs.opencode
  ];

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
  ];
  home.global-persistence.files = [
    ".claude.json"
  ];
}
