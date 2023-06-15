{
  config,
  pkgs,
  lib,
  osConfig,
  ...
}: let
  yq = "${pkgs.yq-go}/bin/yq";
  home = "${config.home.homeDirectory}";
  rimeConfig = ".local/share/fcitx5/rime";
  installationCustom = ''
    sync_dir: "${home}/Syncthing/Main/rime"
    installation_id: "${osConfig.networking.hostName}"
  '';
in {
  home.activation.patchRimeInstallation = lib.hm.dag.entryAfter ["writeBoundary"] ''
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

  home.global-persistence.directories = [
    rimeConfig
  ];
}
