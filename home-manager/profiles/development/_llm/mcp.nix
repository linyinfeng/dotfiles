{
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  mineruMcp = pkgs.writeShellScriptBin "mineru-open-mcp-wrapped" ''
    export MINERU_API_TOKEN="$(cat "${osConfig.sops.secrets."mineru_api_key".path}")"
    exec ${lib.getExe' pkgs.uv "uvx"} mineru-open-mcp "$@"
  '';
in
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
        mineru = {
          command = lib.getExe mineruMcp;
          env = {
            "MINERU_DEFAULT_MODEL" = "vlm";
            "ALL_PROXY" = "";
            "all_proxy" = "";
          };
        };
      };
  };
}
