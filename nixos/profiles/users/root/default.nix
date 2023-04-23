{config, ...}: let
  homeDirectory = "/root";
in {
  users.users.root = {
    passwordFile = config.sops.secrets."user-password/root".path;
    openssh.authorizedKeys.keyFiles = [
      _ssh/pgp.pub
      _ssh/juice.pub
    ];
  };

  environment.global-persistence.user.users = ["root"];
  home-manager.users.root = {suites, ...}: {
    imports = suites.base;
    home.global-persistence = {
      enable = true;
      home = homeDirectory;
    };
  };

  sops.secrets."user-password/root" = {
    neededForUsers = true;
    sopsFile = config.sops-file.get "common.yaml";
  };
}
