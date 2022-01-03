{ config, ... }:

{
  users.users.root = {
    passwordFile = config.sops.secrets."user-password/root".path;
    openssh.authorizedKeys.keyFiles = [
      ../yinfeng/ssh/authorized-keys/pgp.pub
    ];
  };

  home-manager.users.root = { suites, ... }: {
    imports = suites.base;
  };

  sops.secrets."user-password/root".neededForUsers = true;
}
