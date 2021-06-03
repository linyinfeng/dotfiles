{ ... }:

let
  common = import ../common.nix;
in
{
  services.portal = {
    inherit (common) host path;
    server.enable = true;
  };
}
