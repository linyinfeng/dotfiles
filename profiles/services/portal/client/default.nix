{ ... }:

let
  common = import ../common.nix;
in
{
  services.portal = {
    inherit (common) host path;
    client = {
      enable = true;
      port = 8080;
    };
  };
}
