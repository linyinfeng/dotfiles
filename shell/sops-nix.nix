{ pkgs, ... }:
let
  pkgWithCategory = category: package: { inherit package category; };
in
{
  commands = map (pkgWithCategory "sops") (with pkgs; [
    sops
    ssh-to-age
    ssh-to-pgp
    # sops-import-keys-hook
  ]);

  env = [
    {
      name = "sopsPGPKeyDirs";
      value = toString [
        ../secrets/keys/hosts
        ../secrets/keys/users
      ];
    }
  ];
}
