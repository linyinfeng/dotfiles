{ pkgs, lib, ... }:
{
  imports = [
    # ./_oh-my-openagent.nix
    ./_lsp.nix
    ./_auth.nix
    ./_skills.nix
  ];
  programs.opencode = {
    enable = true;
    package = pkgs.writeShellApplication {
      name = "opencode";
      runtimeInputs = with pkgs; [
        opencode
      ];
      runtimeEnv = {
        NIX_LD_LIBRARY_PATH = lib.makeLibraryPath pkgs.pythonManylinuxPackages.manylinux1;
      };
      text = ''
        # cleanup environment variables
        export -n ALL_PROXY
        export -n all_proxy
        exec opencode "$@"
      '';
    };
    enableMcpIntegration = true;
    extraPackages = with pkgs; [
      opencode
      python3
      uv
      nodejs
      # bun # AI slop
      pnpm
      gcc # allow build some python packages
    ];
  };
}
