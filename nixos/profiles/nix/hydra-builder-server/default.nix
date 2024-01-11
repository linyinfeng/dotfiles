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

  nix.settings.extra-sandbox-paths = [
    config.sops.templates."linux-module-signing-key.pem".path
    config.sops.secrets."secure_boot_db_private_key".path
  ];
  sops.templates."linux-module-signing-key.pem" = {
    content = ''
      ${config.lib.self.data.secure_boot_db_cert_pem}
      ${config.sops.placeholder."secure_boot_db_private_key"}
    '';
    group = "nixbld";
    mode = "440";
  };
  sops.secrets."secure_boot_db_private_key" = {
    terraformOutput.enable = true;
    group = "nixbld";
    mode = "440";
    restartUnits = []; # no need to restart any unit
  };
}
