{
  osConfig,
  pkgs,
  lib,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
  };
  programs.antigravity-cli = {
    enable = true;
    enableMcpIntegration = true;
  };
  programs.mcp = {
    enable = true;
    servers =
      let
        simpleMcps = with pkgs; [
          mcp-nixos
          mcp-server-git
          mcp-server-time
          mcp-server-fetch
          mcp-nixos
        ];
      in
      lib.listToAttrs (lib.map (p: lib.nameValuePair p.pname { command = lib.getExe p; }) simpleMcps)
      // {
        # zotero-mcp = {
        #   command = lib.getExe' pkgs.uv "uvx";
        #   args = [
        #     "--from"
        #     "zotero-mcp-server"
        #     "zotero-mcp"
        #   ];
        #   env = {
        #     "ZOTERO_LOCAL" = "true";
        #     "LD_LIBRARY_PATH" = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
        #   };
        # };
      };
  };

  home.packages = [
    pkgs.nono
    pkgs.linyinfeng.deepseek-reasonix
    (pkgs.writeShellApplication {
      name = "claude-deepseek";
      text = ''
        export ANTHROPIC_BASE_URL="https://api.deepseek.com/anthropic"
        ANTHROPIC_AUTH_TOKEN="$(cat "${osConfig.sops.secrets."deepseek_api_key".path}")"
        export ANTHROPIC_AUTH_TOKEN
        export ANTHROPIC_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="deepseek-v4-pro[1m]"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="deepseek-v4-flash"
        export CLAUDE_CODE_SUBAGENT_MODEL="deepseek-v4-flash"
        export CLAUDE_CODE_EFFORT_LEVEL="max"
        export -n all_proxy
        export -n ALL_PROXY
        exec claude "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "claude-mimo";
      text = ''
        export ANTHROPIC_BASE_URL="https://token-plan-cn.xiaomimimo.com/anthropic"
        ANTHROPIC_AUTH_TOKEN="$(cat "${osConfig.sops.secrets."mimo_token_plan_api_key".path}")"
        export ANTHROPIC_AUTH_TOKEN
        export ANTHROPIC_MODEL="mimo-v2.5-pro"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="mimo-v2.5-pro"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="mimo-v2.5"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="mimo-v2.5"
        export -n all_proxy
        export -n ALL_PROXY
        exec claude "$@"
      '';
    })
    (pkgs.writeShellApplication {
      name = "claude-mimo-1m";
      text = ''
        export ANTHROPIC_BASE_URL="https://token-plan-cn.xiaomimimo.com/anthropic"
        ANTHROPIC_AUTH_TOKEN="$(cat "${osConfig.sops.secrets."mimo_token_plan_api_key".path}")"
        export ANTHROPIC_AUTH_TOKEN
        export ANTHROPIC_MODEL="mimo-v2.5-pro[1m]"
        export ANTHROPIC_DEFAULT_OPUS_MODEL="mimo-v2.5-pro[1m]"
        export ANTHROPIC_DEFAULT_SONNET_MODEL="mimo-v2.5[1m]"
        export ANTHROPIC_DEFAULT_HAIKU_MODEL="mimo-v2.5[1m]"
        export -n all_proxy
        export -n ALL_PROXY
        exec claude "$@"
      '';
    })
  ];

  home.global-persistence.directories = [
    ".claude"
    ".gemini"
    ".continue"
    ".codebuddy"
    ".config/reasonix"
    ".config/opencode"
    ".config/kilo"
  ];
  home.global-persistence.files = [
    ".claude.json"
  ];
}
