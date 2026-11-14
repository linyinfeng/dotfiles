{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkMerge [
  {
    environment.systemPackages = with pkgs; [
      zellij
    ];
  }
  (lib.mkIf (lib.elem "workstation" config.system.types) {
    environment.systemPackages = with pkgs; [
      wezterm
    ];
  })
]
