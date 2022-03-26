{ config, lib, pkgs, ... }:

let
  gameHome = config.users.users.steam.home;
  dstRoot = "Games/dst";
  dstAppDir = "${dstRoot}/app";
  dstApp = "343050";
  dstStorageDir = "${dstRoot}/storage";
in
{
  home-manager.users.steam = {
    home.global-persistence.directories = [
      dstRoot
    ];
  };
  systemd.services.dst = {
    script = ''
      # install game
      steamcmd \
        +force_install_dir "${gameHome}/${dstAppDir}" \
        +login anonymous \
        +app_update "${dstApp}" validate \
        +quit

      # start server
      cd "${gameHome}/${dstAppDir}/bin"
      steam-run ./dontstarve_dedicated_server_nullrenderer \
        -persistent_storage_root "${gameHome}/${dstStorageDir}" -conf_dir config
    '';
    path = with pkgs; [ steamcmd steam-run ];
    serviceConfig = {
      User = "steam";
      Group = "steam";
    };
    wantedBy = [ "multi-user.target" ];
  };
  # networking.firewall.allowedUDPPorts = [
  #   11000 11001
  # ];
}
