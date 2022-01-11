{ config, pkgs, lib, ... }:

let
  name = "nianyi";
  uid = config.ids.uids.${name};
  user = config.users.users.${name};
  homeManager = config.home-manager.users.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent = name: lib.optional
    (config.users.groups ? ${name})
    config.users.groups.${name}.name;
in
{
  users.users.${name} = {
    inherit uid;
    isNormalUser = true;
    shell = pkgs.bash;
    home = homeDirectory;
    extraGroups = with config.users.groups; [
      users.name
    ];

    openssh.authorizedKeys.keyFiles = [
      ./ssh/id_rsa.pub
    ];
  };

  home-manager.users.${name} = { pkgs, suites, ... }: {
    passthrough.systemConfig = config;
    home.global-persistence.enable = true;

    home.packages = with pkgs; [
      tmux
      go-shadowsocks2
    ];

    home.global-persistence.directories = [
      "data"
    ];
  };

  environment.global-persistence.directories =
    map (dir: "${homeDirectory}/${dir}")
      homeManager.home.global-persistence.directories;
}
