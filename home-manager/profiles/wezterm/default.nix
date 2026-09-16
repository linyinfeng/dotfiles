{
  config,
  lib,
  ...
}:
{
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local config = wezterm.config_builder()

      config.color_scheme = "Noctalia"
      config.font = wezterm.font('monospace')

      config.unix_domains = {
        {
          name = 'unix',
        },
      }
      config.ssh_domains = {
        ${lib.concatMapStringsSep "\n" (h: ''
          {
              name = "${h}",
              remote_address = "${h}.dn42.li7g.com:${toString config.home.env.sshPort}",
              username = "root",
            },
            {
              name = "${h}.dn42",
              remote_address = "${h}.dn42.li7g.com:${toString config.home.env.sshPort}",
              username = "root",
            },
            {
              name = "${h}.ts",
              remote_address = "${h}.ts.li7g.com:${toString config.home.env.sshPort}",
              username = "root",
            },
        '') config.home.env.hosts}
      }

      return config
    '';
  };
}
