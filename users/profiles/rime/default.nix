{ config, pkgs, lib, ... }:
let
  yq = "${pkgs.yq-go}/bin/yq";
  home = "${config.home.homeDirectory}";
  rimeConfig = ".config/ibus/rime";
  installationCustom = ''
    sync_dir: "${home}/OneDrive/Documents/RIME"
    installation_id: "${config.passthrough.systemConfig.networking.hostName}"
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
  home.file.".config/ibus/rime/build/ibus_rime.yaml".text = ''
    style:
      horizontal: true
  '';

  home.global-persistence.directories = [
    ".config/ibus/rime"
  ];
}
