# TODO: remove this after https://github.com/NixOS/nixpkgs/pull/130985 being merged into unstable channel
channels: final: prev: {
  system-config-printer = channels.latest.system-config-printer;
}
