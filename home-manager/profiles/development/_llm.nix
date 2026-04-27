{ ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
  programs.bun.enable = true;
  programs.gemini-cli = {
    enable = true;
    enableMcpIntegration = true;
  };

  home.global-persistence.directories = [
    ".claude"
    ".gemini"
    ".continue"
  ];
}
