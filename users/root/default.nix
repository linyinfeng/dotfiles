{ config, ... }:

{
  users.users.root = {
    passwordFile = config.sops.secrets."user-password/root".path;
    openssh.authorizedKeys.keyFiles = [
      ../yinfeng/ssh/id_ed25519.pub
      ./ssh/actions.pub
    ];
  };

  home-manager.users.root = { suites, ... }: {
    imports = suites.base;
  };

  sops.secrets."user-password/root".neededForUsers = true;
}
