{ config, pkgs, lib, osConfig, ... }:
let
  yq = "${pkgs.yq-go}/bin/yq";
  home = "${config.home.homeDirectory}";
  rimeConfig = ".config/ibus/rime";
  installationCustom = ''
    sync_dir: "${home}/Syncthing/Main/rime"
    installation_id: "${osConfig.networking.hostName}"
  '';
in
lib.mkIf config.home.graphical {
  # sync causing problem
  # home.activation.patchRimeInstallation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
  #   target="${home}/${rimeConfig}/installation.yaml"
  #   if [ -e "$target" ]; then
  #     ${yq} eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' "$target" - --inplace <<EOF
  #   ${installationCustom}
  #   EOF
  #   fi
  # '';
  home.file.".config/ibus/rime/default.custom.yaml".text = ''
    patch:
      schema_list:
        - schema: rime_ice
  '';

  home.file.".config/ibus/rime/ibus_rime.custom.yaml".text = ''
    patch:
      style:
        horizontal: true
  '';

  home.global-persistence.directories = [
    ".config/ibus/rime"
  ];
}
