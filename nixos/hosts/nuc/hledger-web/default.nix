{config, ...}:

let
  stateDir = "/home/yinfeng/Syncthing/Main/ledger";
in{
  services.hledger-web = {
    enable = true;
    capabilities = {
      view = true;
      add = true;
      manage = true;
    };
    port = config.ports.hledger-web;
    stateDir = stateDir;
    journalFiles = [
      "main.journal"
    ];
  };
  systemd.tmpfiles.rules = [
    ''a+ "/home/yinfeng" - - - - mask::r-x,user:${config.users.users.hledger.name}:r-x''
    ''a+ "/home/yinfeng/Syncthing" - - - - mask::r-x,user:${config.users.users.hledger.name}:r-x''
    ''a+ "${stateDir}" - - - - mask::rwx,user:${config.users.users.hledger.name}:rwx''
    ''a+ "${stateDir}/main.journal" - - - - mask::rw-,user:${config.users.users.hledger.name}:rw-''
  ];
  services.nginx.virtualHosts."hledger.*" = {
    listen = config.hosts.nuc.listens;
    forceSSL = true;
    useACMEHost = "main";
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString config.ports.hledger-web}";
      extraConfig = ''
        auth_basic "hledger";
        auth_basic_user_file ${config.sops.templates."hledger-auth-file".path};
      '';
    };
  };
  systemd.services.nginx.restartTriggers = [
    config.sops.templates."hledger-auth-file".file
  ];
  sops.templates."hledger-auth-file" = {
    content = ''
      ${config.sops.placeholder."hledger_username"}:${config.sops.placeholder."hledger_hashed_password"}
    '';
    owner = config.users.users.nginx.name;
  };
  sops.secrets."hledger_username" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["nginx.service"];
  };
  sops.secrets."hledger_hashed_password" = {
    sopsFile = config.sops-file.terraform;
    restartUnits = ["nginx.service"];
  };
  services.restic.backups.b2.paths = [
    "/var/lib/hledger"
  ];
}
