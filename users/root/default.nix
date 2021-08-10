{ config, ... }:

{
  users.users.root = {
    passwordFile = config.age.secrets.user-root-password.path;
    openssh.authorizedKeys.keyFiles = [
      ../yinfeng/ssh/id_ed25519.pub
    ];
  };

  age.secrets.user-root-password.file = ../../secrets/user-root-password.age;

  home-manager.users.root = { suites, ... }: {
    imports = suites.base;
  };
}
