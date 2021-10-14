{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.home.roaming;
  fw-proxy = config.passthrough.systemConfig.networking.fw-proxy;
in
{
  options.home.roaming = {
    enable = mkOption {
      type = with types; bool;
      default = false;
      description = ''
        Weather to enable roaming folder.
      '';
    };
    onCalendar = mkOption {
      type = with types; str;
      default = "*:0/5";
      description = ''
        Timer OnCalendar configuration.
      '';
    };
    path = mkOption {
      type = with types; path;
      default = "${config.home.homeDirectory}/Roaming";
      description = ''
        Path of roaming directory.
      '';
    };
    url = mkOption {
      type = with types; str;
      description = ''
        Git repository.
      '';
    };
  };
  config = mkIf cfg.enable {
    systemd.user.timers.roaming = {
      Timer = {
        OnCalendar = cfg.onCalendar;
      };
      Install = {
        WantedBy = [ "timers.target" ];
      };
    };
    systemd.user.services.roaming =
      let script = pkgs.writeShellScript "update-roaming" ''
        set -e

        function step {
          echo -n "-- "
          echo -n -e "\033[0;32m"
          echo -n "$@"
          echo -e "\033[0m"
        }
        git="${pkgs.git}/bin/git"

        date=$("${pkgs.coreutils}/bin/date" --iso-8601=seconds)

        if [ ! -d "${cfg.path}" ]; then
          step "clone"; $git clone "${cfg.url}" "${cfg.path}"
        fi
        cd "${cfg.path}"
        skip="false"
        if [ -z "$(git status --porcelain)" ]; then
          skip="true"
        fi
        if [ "$skip" = "false" ]; then
          step "add"; $git add --all --verbose
          step "commit"; $git commit --message "update at $date" --verbose
        fi
        step "pull"; $git pull --ff-only --verbose
        if [ "$skip" = "false" ]; then
          step "push"; $git push --verbose
        fi
      '';
      in
      {
        Service = {
          ExecStart = "${script}";
          Environment = mkIf fw-proxy.enable fw-proxy.stringEnvironment;
        };
      };
  };
}
