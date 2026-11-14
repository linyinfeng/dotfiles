{
  config,
  lib,
  pkgs,
  ...
}:
let
  themeDir = "${config.xdg.stateHome}/btop";
  themeFile = "${themeDir}/current.theme";
  themes = "${config.programs.btop.package}/share/btop/themes";
  switchTheme = pkgs.writeShellApplication {
    name = "darkman-switch-btop";
    runtimeInputs = with pkgs; [
      coreutils
      procps
    ];
    text = ''
      mode="$1"
      case "$mode" in
        light) theme="adwaita" ;;
        dark) theme="adwaita-dark" ;;
        *) exit 1 ;;
      esac

      mkdir -p ${lib.escapeShellArg themeDir}
      ln -sfn "${themes}/$theme.theme" ${lib.escapeShellArg themeFile}

      # No running btop is also a successful switch.
      pkill -USR2 -u "$(id -u)" -x btop || [[ $? == 1 ]]
    '';
  };
in
{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = themeFile;
      update_ms = 1000;
    };
  };

  systemd.user.tmpfiles.rules = lib.mkIf pkgs.stdenv.hostPlatform.isLinux [
    "d ${themeDir} 0700 - - -"
    "L ${themeFile} - - - - ${themes}/adwaita-dark.theme"
  ];

  services.darkman = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
    lightModeScripts.btop = "${lib.getExe switchTheme} light";
    darkModeScripts.btop = "${lib.getExe switchTheme} dark";
  };
}
