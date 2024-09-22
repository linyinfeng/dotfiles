{ config, ... }:
{
  services.mongodb = {
    enable = true;
    enableAuth = true;
    extraConfig = ''
      net.port: ${toString config.ports.mongodb}
    '';
    initialRootPassword = "temporary"; # will be replaced in initialScript
    initialScript = config.sops.templates."mongodb-init.js".path;
  };
  sops.templates."mongodb-init.js" = {
    content = ''
      db.changeUserPassword("root", "${config.sops.placeholder."mongodb_admin_password"}")
    '';
    owner = config.services.mongodb.user;
  };
  sops.secrets."mongodb_admin_password" = {
    terraformOutput.enable = true;
    restartUnits = [ ]; # needs manual rotation
  };
}
