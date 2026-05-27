{ pkgs, lib, ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
  };
  programs.gemini-cli = {
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
        ];
      in
      lib.listToAttrs (lib.map (p: lib.nameValuePair p.name { command = lib.getExe p; }) simpleMcps)
      // {
        mcp-nixos = {
          command = lib.getExe pkgs.mcp-nixos;
          env = {
            all_proxy = "";
            ALL_PROXY = "";
          };
        };
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

  home.global-persistence.directories = [
    ".claude"
    ".gemini"
    ".continue"
    ".config/opencode"
  ];
  home.global-persistence.files = [
    ".claude.json"
  ];
}
