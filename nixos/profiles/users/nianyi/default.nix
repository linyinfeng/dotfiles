{
  config,
  pkgs,
  lib,
  ...
}: let
  name = "nianyi";
  uid = config.ids.uids.${name};
  user = config.users.users.${name};
  homeManager = config.home-manager.users.${name};
  homeDirectory = "/home/${name}";

  groupNameIfPresent = name:
    lib.optional
    (config.users.groups ? ${name})
    config.users.groups.${name}.name;
in {
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

  environment.global-persistence.user.users = [name];
  home-manager.users.${name} = {
    pkgs,
    suites,
    ...
  }: {
    home.global-persistence = {
      enable = true;
      home = homeDirectory;
    };

    home.packages = with pkgs; [
      tmux
      vim
      emacs
      go-shadowsocks2
    ];

    home.global-persistence.directories = [
      "data"
    ];
  };
}
