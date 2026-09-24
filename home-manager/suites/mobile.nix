{ ... }:
{
  world = {
    profiles = {
      browsers.enable = true;
      dconf-proxy.enable = true;
      development.enable = true;
      git.enable = true;
      mime.enable = true;
      rime.enable = true;
      shells.enable = true;
      ssh.enable = true;
      xdg-dirs.enable = true;
    };
    suites = {
      base.enable = true;
      other.enable = true;
      security.enable = true;
    };
  };
}
