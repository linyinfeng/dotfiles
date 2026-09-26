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
    # graphical-session.target also gets activated in display-less sessions
    # (darkman is D-Bus activated by emacs under default.target), where this
    # X11 overlay segfaults and crash-loops.
    unitConfig.ConditionEnvironment = "DISPLAY";
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
