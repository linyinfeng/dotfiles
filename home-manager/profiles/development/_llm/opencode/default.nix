{ pkgs, ... }:
{
  imports = [
    ./oh-my-openagent.nix
    ./lsp.nix
  ];
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    extraPackages = with pkgs; [
      python3
      uv
      nodejs
      bun
      pnpm
    ];
    settings = {
      plugin = [ "oh-my-openagent@latest" ];
    };
  };

  home.global-persistence.directories = [
    ".config/opencode"
    ".local/share/opencode"
    ".cache/opencode"
    ".cache/bun"
  ];
}
