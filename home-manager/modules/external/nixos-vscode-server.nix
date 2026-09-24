{ inputs, ... }:
{
  imports = [ inputs.nixos-vscode-server.homeModules.default ];
}
