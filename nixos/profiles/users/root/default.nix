{ config, ... }:
let
  homeDirectory = "/root";
in
{
  users.users.root = {
    hashedPasswordFile = config.sops.secrets."user_password_root".path;
    openssh.authorizedKeys.keyFiles = [
      _ssh/pgp.pub
      _ssh/juice.pub
    ];
  };

  environment.global-persistence.user.users = [ "root" ];
  home-manager.users.root =
    { suites, ... }:
    {
      imports = suites.base;
      home.global-persistence = {
        enable = true;
        home = homeDirectory;
      };
    };

  sops.secrets."user_password_root" = {
    predefined.enable = true;
    neededForUsers = true;
  };
}
