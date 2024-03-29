{ config, lib, ... }:
let
  cfg = config.networking.hostsData;
  inherit (config.lib.self) data;
  inherit (config.networking) hostName;
in
{
  options.networking.hostsData = {
    indexedHosts = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = lib.filterAttrs (_: hostData: (lib.length hostData.host_indices != 0)) data.hosts;
      readOnly = true;
    };
    indexed = lib.mkOption {
      type = with lib.types; bool;
      default = cfg.indexedHosts ? ${hostName};
      readOnly = true;
    };
  };
}
