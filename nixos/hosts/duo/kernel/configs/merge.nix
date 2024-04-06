{ lib }:
let
  inherit (lib.kernel) yes module;
in
{
  SECURITY = yes;
  LIBCRC32C = module;
  PROC_CHILDREN = yes;
  SYN_COOKIES = yes;
  BRIDGE = module;
  NET_IPVTI = module;
  NETWORK_SECMARK = yes;
}
