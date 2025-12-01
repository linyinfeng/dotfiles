{ config, lib, ... }:
let
  inherit (config.lib.self) data;
  hostList = lib.flatten (
    lib.mapAttrsToList (
      name: hostData:
      lib.lists.map (ip: {
        hostName = "${name}.endpoints.li7g.com";
        inherit ip;
      }) (hostData.endpoints_v4 ++ hostData.endpoints_v6)
    ) data.hosts
  );
in
{
  networking.hosts = lib.foldr (
    entry: m: m // { ${entry.ip} = (m.${entry.ip} or [ ]) ++ [ entry.hostName ]; }
  ) { } hostList;
  passthru.hostList = hostList;
}
