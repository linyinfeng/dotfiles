{ pkgs, lib, ... }:
let
  title = "         NixOS Insider Preview";
  message = "Evaluation Copy. Build ${lib.version}";
in
{
  systemd.user.services.activate-linux = {
    description = "Activate NixOS";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    path = [ pkgs.activate-linux ];
    script = ''
      activate-linux \
        --overlay-width 400 --overlay-height 80 \
        --text-title "${title}" \
        --text-message "${message}" \
        --text-font "monospace"
    '';
    serviceConfig = {
      Restart = "on-failure";
    };
  };
}
