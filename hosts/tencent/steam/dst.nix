{ config, lib, pkgs, ... }:

let
  gameHome = config.users.users.steam.home;
  dstRoot = "Games/dst";
  dstAppDir = "${dstRoot}/app";
  dstApp = "343050";
  dstStorageDir = "${dstRoot}/storage";
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

      # create running indicator
      touch "${gameHome}/${dstRunnigIndicator}"

      # start server
      cd "${gameHome}/${dstAppDir}/bin64"
      run_shared=(steam-run)
      run_shared+=(./dontstarve_dedicated_server_nullrenderer_x64)
      run_shared+=(-persistent_storage_root "${gameHome}/${dstStorageDir}")
      run_shared+=(-conf_dir config)
      run_shared+=(-cluster "Main")
      run_shared+=(-monitor_parent_process $$)
      socat pty,link="${gameHome}/${dstTTYCaves}",raw STDOUT | \
      "''${run_shared[@]}" -shard Caves  -console | sed --unbuffered 's/^/Caves:  /' &
      socat pty,link="${gameHome}/${dstTTYMaster}",raw STDOUT | \
      "''${run_shared[@]}" -shard Master -console | sed --unbuffered 's/^/Master: /' &

      wait

      # delete running indicator
      rm "${gameHome}/${dstRunnigIndicator}"
    '';
    path = with pkgs; [ steamcmd steam-run socat ];
    serviceConfig = {
      User = "steam";
      Group = "steam";
      ExecStop = stopScript;
    };
    wantedBy = [ "multi-user.target" ];
  };
  networking.firewall.allowedUDPPorts = [
    10999
  ];
}
