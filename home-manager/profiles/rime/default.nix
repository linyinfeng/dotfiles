{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}:
let
  yq = "${pkgs.yq-go}/bin/yq";
  home = "${config.home.homeDirectory}";
  rimeConfig =
    if osConfig.i18n.inputMethod.enabled == "fcitx5" then
      ".local/share/fcitx5/rime"
    else if osConfig.i18n.inputMethod.enabled == "ibus" then
      ".config/ibus/rime"
    else
      throw "unable to determine rime config directory";
  installationCustom = ''
    sync_dir: "${home}/Syncthing/Main/rime"
    installation_id: "${osConfig.networking.hostName}"
  '';
in
{
  home.activation.patchRimeInstallation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    target="${home}/${rimeConfig}/installation.yaml"
    if [ -e "$target" ]; then
      ${yq} eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$target" - --inplace <<EOF
    ${installationCustom}
    EOF
    fi
  '';
  home.file.${rimeConfig} = {
    source = ./_user-data;
    recursive = true;
  };
}
