{ config, lib, ... }:
{
  xdg.configFile."fcitx5" = {
    source = ./_config;
    recursive = true;
  };
  home.activation.removeExistingFcitx5Profile = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm --recursive --force \
      "${config.xdg.configHome}/fcitx5/profile" \
      "${config.xdg.configHome}/fcitx5/config" \
      "${config.xdg.configHome}/fcitx5/conf"
  '';
}
