{
  config,
  pkgs,
  lib,
  ...
}: let
  hosts = lib.attrNames config.lib.self.data.hosts;
  hostsSpecs = lib.lists.map (h: "root@${h}") hosts;
  hostsFile = pkgs.writeText "pssh-hosts" ''
    ${lib.concatStringsSep "\n" hostsSpecs}
  '';
in {
  home.packages = with pkgs; [
    pssh
  ];
  home.shellAliases = {
    pssh = "pssh --hosts=${hostsFile}";
  };
  passthru.pssh-host-file = hostsFile;
}
