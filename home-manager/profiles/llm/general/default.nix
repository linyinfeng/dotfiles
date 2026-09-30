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
      llm-agents.claude-code
      llm-agents.codex
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

  systemd.user.services.codex-app-server = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    Unit = {
      Description = "Codex app-server daemon";
      After = [ "default.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe pkgs.llm-agents.codex} app-server daemon start";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
