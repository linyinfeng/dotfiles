{ config, lib, ... }:
{
  xdg.configFile."fcitx5" = {
    source = ./_config;
    recursive = true;
  };
  home.activation.removeExistingFcitx5Profile = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f "${config.xdg.configHome}/fcitx5/profile"
    rm -f "${config.xdg.configHome}/fcitx5/config"
  '';
}
