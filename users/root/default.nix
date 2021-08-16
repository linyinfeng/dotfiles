{ config, ... }:

{
  users.users.root = {
    passwordFile = config.age.secrets.user-root-password.path;
    openssh.authorizedKeys.keyFiles = [
      ../yinfeng/ssh/id_ed25519.pub
      ./ssh/actions.pub
    ];
  };

  age.secrets.user-root-password.file = config.age.secrets-directory + /user-root-password.age;

  home-manager.users.root = { suites, ... }: {
    imports = suites.base;
  };
}
