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

  environment = {
    systemPackages = optionalPkg [ "xwayland-satellite" ];
    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  environment.global-persistence.user = {
    directories = [
      ".cache/thumbnails"
      ".local/share/applications"
      ".local/share/backgrounds"
      ".local/share/icc"
      ".local/share/keyrings"
      ".local/share/Trash"
    ];
    files = [ ".face" ];
  };
}
