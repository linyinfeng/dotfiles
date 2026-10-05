{
  config,
  pkgs,
  ...
}:
let
  optionalPkg = config.lib.self.optionalPkg pkgs;
in
{
  programs.niri.enable = true;

  environment.systemPackages = optionalPkg [ "xwayland-satellite" ];
}
