{ pkgs, lib, ... }:
{
  programs.mcp = {
    enable = true;
    servers =
      let
        simpleMcps = with pkgs; [
          mcp-nixos
        ];
      in
      lib.listToAttrs (
        lib.map (
          p:
          lib.nameValuePair p.pname {
            command = lib.getExe p;
            env = {
              # some python MCP does not support SOCKS 5 proxies
              "ALL_PROXY" = "";
              "all_proxy" = "";
            };
          }
        ) simpleMcps
      )
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
}
