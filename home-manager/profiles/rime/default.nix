{
  config,
  pkgs,
  lib,
  ...
}:
let
  yq = "${pkgs.yq-go}/bin/yq";
  home = "${config.home.homeDirectory}";
  rimeConfig =
    if config.home.env.inputMethod == null then
      null
    else if config.home.env.inputMethod == "fcitx5" then
      ".local/share/fcitx5/rime"
    else
      ".config/ibus/rime";
  installationCustom = ''
    sync_dir: "${home}/Syncthing/Main/rime"
    installation_id: "${config.home.env.hostName}"
  '';
in
{
  config = lib.mkIf (rimeConfig != null) {
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
  };
}
