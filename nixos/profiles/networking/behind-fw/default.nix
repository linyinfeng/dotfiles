{
  config,
  lib,
  ...
}: {
  nix.settings.substituters = lib.mkOrder 900 [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];
}
