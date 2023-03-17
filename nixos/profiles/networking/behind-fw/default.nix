{
  config,
  lib,
  ...
}: {
  nix.settings.substituters = lib.mkOrder 900 [
    # TODO tuna is slow currently
    # "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  ];
}
