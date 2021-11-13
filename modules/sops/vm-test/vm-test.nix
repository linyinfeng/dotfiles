{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (config.system.is-vm) {
    sops.defaultSopsFile = lib.mkForce ./test-secrets.yaml;
    sops.age.sshKeyPaths = lib.mkForce [ ];
    sops.age.keyFile = ./test-key.txt;
  };
}
