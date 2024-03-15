{
  config,
  lib,
  pkgs,
  ...
}:
let
  gameHome = config.users.users.steam.home;
  dstRoot = "Games/dst";
  dstAppDir = "${dstRoot}/app";
  dstApp = "343050";
  dstStorageDir = "${dstRoot}/storage";
  dstConfigDirName = "config";
  dstClusterName = "Main";
  dstClusterDir = "${dstStorageDir}/${dstConfigDirName}/${dstClusterName}";
  dstTTYCaves = "${dstRoot}/tty-caves";
  dstTTYMaster = "${dstRoot}/tty-master";
  dstRunnigIndicator = "${dstRoot}/running";
  stopScript = pkgs.writeShellScript "dst-stop" ''
    echo "write c_shutdown(true)"
    echo "c_shutdown(true)" > "${gameHome}/${dstTTYCaves}"
    echo "c_shutdown(true)" > "${gameHome}/${dstTTYMaster}"
    while [ -f "${gameHome}/${dstRunnigIndicator}" ]; do sleep 1; done
    echo "shutdown done"
  '';
in
{
  home-manager.users.steam = {
    home.global-persistence.directories = [ dstRoot ];
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
      # modify settings
      cp ${./modoverrides.lua} "${gameHome}/${dstClusterDir}/Master/modoverrides.lua"
      cp ${./modoverrides.lua} "${gameHome}/${dstClusterDir}/Caves/modoverrides.lua"
      cp ${./Master/worldgenoverride.lua} "${gameHome}/${dstClusterDir}/Master/worldgenoverride.lua"
      cp ${./Caves/worldgenoverride.lua} "${gameHome}/${dstClusterDir}/Caves/worldgenoverride.lua"

      # create running indicator
      touch "${gameHome}/${dstRunnigIndicator}"

      # start server
      cd "${gameHome}/${dstAppDir}/bin64"
      run_shared=(steam-run)
      run_shared+=(./dontstarve_dedicated_server_nullrenderer_x64)
      run_shared+=(-persistent_storage_root "${gameHome}/${dstStorageDir}")
      run_shared+=(-conf_dir "${dstConfigDirName}")
      run_shared+=(-cluster "${dstClusterName}")
      run_shared+=(-monitor_parent_process $$)
      socat pty,link="${gameHome}/${dstTTYCaves}",raw STDOUT | \
      "''${run_shared[@]}" -shard Caves  -console | sed --unbuffered 's/^/Caves:  /' &
      socat pty,link="${gameHome}/${dstTTYMaster}",raw STDOUT | \
      "''${run_shared[@]}" -shard Master -console | sed --unbuffered 's/^/Master: /' &

      wait

      # delete running indicator
      rm "${gameHome}/${dstRunnigIndicator}"
    '';
    path = with pkgs; [
      steamcmd
      steam-run
      socat
    ];
    serviceConfig = {
      User = "steam";
      Group = "steam";
      ExecStop = stopScript;
      CPUQuota = "150%"; # at most 1.5 core (2 cores in total)
    };
    environment = lib.mkIf (config.networking.fw-proxy.enable) config.networking.fw-proxy.environment;
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedUDPPorts = [ 10999 ];
}
