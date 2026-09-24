{ config, ... }:
{
  users.users.root = {
    hashedPasswordFile = config.sops.secrets."user_password_root".path;
    openssh.authorizedKeys.keyFiles = [
      _ssh/pgp.pub
      _ssh/juice.pub
      _ssh/goose.pub
    ];
  };

  environment.global-persistence.user.users = [ "root" ];
  home-manager.users.root =
    { lib, ... }:
    {
      world.suites.base.enable = lib.mkDefault true;
      home.global-persistence.enable = true;
    };

  sops.secrets."user_password_root" = {
    predefined.enable = true;
    neededForUsers = true;
  };
}
