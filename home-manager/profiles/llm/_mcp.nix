{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  mineruMcp = pkgs.writeShellApplication {
    name = "mineru-open-mcp";
    runtimeInputs = with pkgs; [
      uv
    ];
    text = ''
      MINERU_API_TOKEN="$(cat "${osConfig.sops.secrets."mineru_api_key".path}")"
      export MINERU_API_TOKEN
      exec uvx mineru-open-mcp "$@"
    '';
  };
in
{
  programs.mcp = {
    enable = true;
    servers =
      let
        simpleMcps = with pkgs; [
          mcp-nixos
          mineruMcp
        ];
      in
      lib.listToAttrs (
        lib.map (
          p:
          lib.nameValuePair (p.pname or p.name) {
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
        # nothing
      };
  };
}
