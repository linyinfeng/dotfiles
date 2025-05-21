{
  osConfig,
  pkgs,
  lib,
  ...
}:
let
  themeFile = ".config/wezterm/theme.lua";
  darkmanSwitch = pkgs.writeShellApplication {
    name = "darkman-switch-wezterm";
    text = ''
      mode="$1"
      if [ "$mode" = light ]; then
        theme="Builtin Tango Light"
      elif [ "$mode" = dark ]; then
        theme="Builtin Tango Dark"
      else
        echo "invalid mode: $mode"
        exit 1
      fi
      cat >~/"${themeFile}" <<EOF
        return "$theme"
      EOF
    '';
  };
in
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local config = wezterm.config_builder()

      function get_appearance()
        if wezterm.gui then
          return wezterm.gui.get_appearance()
        end
        return 'Dark'
      end

      function scheme_for_appearance(appearance)
        if appearance:find 'Dark' then
          return 'Builtin Tango Dark'
        else
          return 'Builtin Tango Light'
        end
      end

      config.color_scheme = scheme_for_appearance(get_appearance())
      config.font = wezterm.font('monospace')

      -- TODO wait for https://github.com/wez/wezterm/issues/5990
      -- config.front_end = 'WebGpu'

      config.unix_domains = {
        {
          name = 'unix',
        },
      }
      config.ssh_domains = {
        ${lib.concatMapStringsSep "\n" (h: ''
          {
              name = "${h}",
              remote_address = "${h}.dn42.li7g.com:${toString osConfig.ports.ssh}",
              username = "root",
            },
            {
              name = "${h}.dn42",
              remote_address = "${h}.dn42.li7g.com:${toString osConfig.ports.ssh}",
              username = "root",
            },
            {
              name = "${h}.ts",
              remote_address = "${h}.ts.li7g.com:${toString osConfig.ports.ssh}",
              username = "root",
            },
        '') (lib.attrNames osConfig.networking.hostsData.indexedHosts)}
      }

      return config
    '';
  };
  systemd.user.tmpfiles.rules = [
    # create theme file if not exists
    ''f %h/${themeFile} - - - - return "Builtin Tango Light"''
  ];
  services.darkman = {
    lightModeScripts.wezterm = "${lib.getExe darkmanSwitch} light";
    darkModeScripts.wezterm = "${lib.getExe darkmanSwitch} dark";
  };
}
