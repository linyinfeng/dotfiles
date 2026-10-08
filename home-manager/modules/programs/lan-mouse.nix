{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.lan-mouse;
  tomlFormat = pkgs.formats.toml { };
in
{
  options.programs.lan-mouse = {
    enable = lib.mkEnableOption "lan-mouse";
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.lan-mouse;
      description = "The lan-mouse package to use.";
    };
    settings = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/lan-mouse/config.toml`.
        See <https://github.com/feschber/lan-mouse> for the available keys.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."lan-mouse/config.toml" = lib.mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "config.toml" cfg.settings;
    };

    systemd.user.services.lan-mouse = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "lan-mouse";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe cfg.package} daemon";
        Restart = "on-failure";
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    launchd.agents.lan-mouse = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe cfg.package)
          "daemon"
        ];
        KeepAlive = true;
      };
    };
  };
}
