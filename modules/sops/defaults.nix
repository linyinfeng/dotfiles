{ config, lib, ... }:

{
  sops.defaultSopsFile = lib.mkDefault ../../secrets/main.yaml;
  sops.gnupg.sshKeyPaths = [ ];
  sops.age.sshKeyPaths = lib.mkDefault [
    (if config.environment.global-persistence.enable
    then "/persist/etc/ssh/ssh_host_ed25519_key"
    else "/etc/ssh/ssh_host_ed25519_key")
  ];
}
