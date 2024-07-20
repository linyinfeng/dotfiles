{ config, pkgs, ... }:
let
  name = "nianyi";
  uid = config.ids.uids.${name};
  homeDirectory = "/home/${name}";
in
{
  users.users.${name} = {
    inherit uid;
    isNormalUser = true;
    shell = pkgs.bash;
    home = homeDirectory;
    extraGroups = with config.users.groups; [ users.name ];

    openssh.authorizedKeys.keyFiles = [ ./_ssh/id_rsa.pub ];
  };

  environment.global-persistence.user.users = [ name ];
  home-manager.users.${name} =
    { pkgs, ... }:
    {
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

      home.global-persistence.directories = [ "data" ];
    };
}
