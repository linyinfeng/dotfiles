{
  profiles,
  config,
  pkgs,
  ...
}:
let
  name = "agent";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";
in
{
  imports = [
    ./_opencode.nix
    profiles.development.llm-keys
  ];
  users.users.${name} = {
    inherit uid;
    isNormalUser = true;
    shell = pkgs.bash;
    home = homeDirectory;
    createHome = false;
    group = name;
    linger = true;
    extraGroups = with config.users.groups; [
      users.name
      keys.name
      llm.name
    ];
    openssh.authorizedKeys.keyFiles = config.users.users.root.openssh.authorizedKeys.keyFiles;
  };
  users.groups.${name}.gid = uid; # use private group
  nix.settings.allowed-users = [ name ];
  environment.global-persistence.directories = [
    {
      directory = homeDirectory;
      user = name;
      group = name;
      mode = "0700";
    }
  ]; # persist the whole home directory
  systemd.services."home-manager-agent" = {
    after = [ "home-agent.mount" ];
    requires = [ "home-agent.mount" ];
  };
  home-manager.users.${name} =
    { suites, profiles, ... }:
    {
      imports =
        suites.base
        ++ (with profiles; [
          git
          llm
          vscode-server
        ]);

      programs.git = {
        settings = {
          user.name = "Nano";
          user.email = "nano@linyinfeng.com";
        };
      };
    };
}
