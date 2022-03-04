{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.system.is-vm) {
    sops.secretsDir = lib.mkForce ./test-secrets;
    sops.age.sshKeyPaths = lib.mkForce [ ];
    sops.age.keyFile = ./test-key.txt;
  };
}
