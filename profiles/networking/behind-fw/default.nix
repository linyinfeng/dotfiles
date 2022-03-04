{ config, lib, ... }:

{
  nix = lib.mkMerge [
    {
      settings.substituters = lib.mkOrder 900 [
        "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      ];
    }
    (lib.mkIf (config.networking.hostName != "nuc") {
      settings.substituters = lib.mkOrder 1100 [
        # priority of cache.nixos.org and its mirror: 40
        # priority of cachix: 41
        "https://nuc.li7g.com:8443/store?priority=50"
      ];
      settings.trusted-public-keys = [
        "cache.li7g.com:YIVuYf8AjnOc5oncjClmtM19RaAZfOKLFFyZUpOrfqM="
      ];
    })
  ];
}
