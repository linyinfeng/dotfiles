{ ... }:
{
  services.vscode-server.enable = true;

  home.global-persistence.directories = [
    ".vscode-server"
  ];
}
