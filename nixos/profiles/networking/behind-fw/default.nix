{
  config,
  lib,
  ...
}: {
  nix.settings.substituters = lib.mkOrder 900 [
    "https://mirrors.cernet.edu.cn/nix-channels/store"
  ];
}
