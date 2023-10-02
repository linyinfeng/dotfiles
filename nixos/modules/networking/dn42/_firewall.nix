{
  config,
  lib,
  ...
}: let
  cfg = config.networking.dn42;
in
  lib.mkIf cfg.firewall.enable {
    networking.nftables.tables.dn42 = {
      family = "inet";
      content = builtins.readFile ./dn42.nft;
    };
  }
