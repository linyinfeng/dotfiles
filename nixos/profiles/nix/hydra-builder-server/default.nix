{
  config,
  pkgs,
  ...
}: {
  users.users.hydra-builder = {
    isSystemUser = true;
    shell = pkgs.bash;
    uid = config.ids.uids.hydra-builder;
    group = "hydra-builder";
    openssh.authorizedKeys.keys = [
      config.lib.self.data.hydra_builder_public_key
    ];
  };
  users.groups.hydra-builder = {
    gid = config.ids.gids.hydra-builder;
  };
  nix.settings.trusted-users = ["@hydra-builder"];
}
