{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.system.is-vm) {
    # TODO refactor ./test-secrets
    sops.secretsDir = lib.mkForce ./test-secrets;
    sops.age.sshKeyPaths = lib.mkForce [ ];
    sops.age.keyFile = ./test-key.txt;
  };
}
