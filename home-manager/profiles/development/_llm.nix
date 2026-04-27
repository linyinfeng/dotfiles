{ ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
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
