{ pkgs, ... }:
let
  gtkgreetCfg = pkgs.writeText "gtkgreet.conf" ''
    exec-once = ${pkgs.greetd.gtkgreet}/bin/gtkgreet --layer-shell --command=Hyprland
  '';
in
{
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/Hyprland --config ${gtkgreetCfg}";
      };
    };
  };
}
