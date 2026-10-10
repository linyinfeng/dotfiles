# the kernel/module signing key pair, shared by secure boot hosts and hydra build agents
{ config, ... }:
let
  inherit (config.lib.self) data;
in
{
  nix.settings.extra-sandbox-paths = [
    config.sops.templates."linux-module-signing-key.pem".path
    config.sops.secrets."secure_boot_db_private_key".path
  ];
  sops.templates."linux-module-signing-key.pem" = {
    content = ''
      ${data.secure_boot_db_cert_pem}
      ${config.sops.placeholder."secure_boot_db_private_key"}
    '';
    group = "nixbld";
    mode = "440";
  };
  sops.secrets."secure_boot_db_private_key" = {
    terraformOutput.enable = true;
    group = "nixbld";
    mode = "440";
    restartUnits = [ ]; # no need to restart any unit
  };
}
