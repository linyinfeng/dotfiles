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

  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  programs.dconf.enable = true;

  services = {
    udisks2.enable = true;

    displayManager.noctalia-greeter = {
      enable = true;
      settings.keyboard.layout = "us";
    };
  };

  environment = {
    systemPackages = [
      pkgs.dconf
      pkgs.glib
      pkgs.gsettings-desktop-schemas
    ]
    ++ optionalPkg [ "xwayland-satellite" ];
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
