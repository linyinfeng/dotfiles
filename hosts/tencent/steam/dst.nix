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

      # install modes
      echo "ServerModCollectionSetup(\"2785301768\")" \
        >> "${gameHome}/${dstAppDir}/mods/dedicated_server_mods_setup.lua"

      # start server
      cd "${gameHome}/${dstAppDir}/bin64"
      run_shared=(steam-run)
      run_shared+=(./dontstarve_dedicated_server_nullrenderer_x64)
      run_shared+=(-persistent_storage_root "${gameHome}/${dstStorageDir}")
      run_shared+=(-conf_dir config)
      run_shared+=(-cluster "Main")
      run_shared+=(-monitor_parent_process $$)
      "''${run_shared[@]}" -shard Caves  | sed 's/^/Caves:  /' &
      "''${run_shared[@]}" -shard Master | sed 's/^/Master: /'
    '';
    path = with pkgs; [ steamcmd steam-run ];
    serviceConfig = {
      User = "steam";
      Group = "steam";
    };
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedUDPPorts = [
    10999
  ];
}
