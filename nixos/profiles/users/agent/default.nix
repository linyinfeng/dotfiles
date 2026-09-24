{
  config,
  lib,
  pkgs,
  ...
}:
let
  name = "agent";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";
  groupNameIfPresent = config.lib.self.groupNameIfPresent config;
in
{
  imports = [
    ./_opencode.nix
    ./_filebrowser.nix
    ./_pi-web.nix
  ];

  world.profiles.development.llm-keys.enable = lib.mkDefault true;
  users.users.${name} = {
    inherit uid;
    isNormalUser = true;
    shell = pkgs.bash;
    home = homeDirectory;
    createHome = false;
    group = name;
    linger = true;
    extraGroups =
      with config.users.groups;
      [
        users.name
        keys.name
        llm.name
      ]
      ++ groupNameIfPresent "nix-access-tokens"
      ++ groupNameIfPresent "hydra-builder-client"
      ++ groupNameIfPresent "tg-send";
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
    { lib, ... }:
    {
      world = {
        profiles = {
          git.enable = lib.mkDefault true;
          llm = {
            general.enable = lib.mkDefault true;
            opencode.enable = lib.mkDefault true;
            pi.enable = lib.mkDefault true;
          };
          shells.enable = lib.mkDefault true;
          vscode-server.enable = lib.mkDefault true;
          xdg-dirs.enable = lib.mkDefault true;
        };
        suites.base.enable = lib.mkDefault true;
      };

      programs.git = {
        settings = {
          user.name = "Nano";
          user.email = "nano@linyinfeng.com";
          # no signing key on this machine; override shared git profile
          commit.gpgSign = lib.mkForce false;
        };
      };

      programs.bash = {
        enable = true;
        bashrcExtra = ''
          source enable-proxy
        '';
      };
    };
}
