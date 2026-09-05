{ config, lib, ... }:
let
  instances = lib.attrNames (lib.filterAttrs (_: c: c.enable) config.services.frp.instances);
in
{
  sops.secrets."frp_token" = {
    terraformOutput.enable = true;
    restartUnits = lib.map (name: "frp-${name}.service") instances;
  };
  sops.templates."frp-token-env".content = ''
    FRP_TOKEN=${config.sops.placeholder."frp_token"}
  '';
}
