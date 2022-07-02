{ config, lib, ... }:

{
  users.users.root.openssh.authorizedKeys.keyFiles =
    map (p: ./ssh/keys/${p}) (lib.attrNames (builtins.readDir ./ssh/keys));

  sops.secrets."user-password/root".sopsFile = lib.mkForce (config.sops.secretsDir + /hosts/g150ts.yaml);
}
