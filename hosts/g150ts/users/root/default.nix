{ config, lib, ... }:

{
  users.users.root.openssh.authorizedKeys.keyFiles =
    map (p: ./ssh/keys + p) [
      /ip-mi10pro
      /ip-y7000
      /matrixlt1
      /matrixlt2
    ];

  sops.secrets."user-password/root".sopsFile = lib.mkForce (config.sops.secretsDir + /g150t-s.yaml);
}
