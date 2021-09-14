{ config, lib, pkgs, ... }:

let
  publicKey = "age17cg7mctcy03vt7wckfezc0xv2ntanhqx48uma9x2cltxatg2dstqx45xhu";
  secretsForTest = {
    campus-net-password = "xxxxxx";
    campus-net-username = "xxxxxx";
    clash-cnix = "xxxxxx";
    clash-dler = "xxxxxx";
    cloudflare-token = "xxxxxx";
    portal-client-id = "00000000-0000-0000-0000-000000000000";
    transmission-credentials = builtins.toJSON {
      rpc-username = "xxxxxx";
      rpc-password = "xxxxxx";
    };
    # Just 123456
    user-root-password = "$6$4RnIhgDxen6$yKiSAezliYeZ4Cf9lXfPSnvMTlGbSGA1vgXNQszn12zUZ9EFwyjw3adgK.mSl2m11JcQJOqffzUVdTELDeyJj0";
    user-yinfeng-password = "$6$4RnIhgDxen6$yKiSAezliYeZ4Cf9lXfPSnvMTlGbSGA1vgXNQszn12zUZ9EFwyjw3adgK.mSl2m11JcQJOqffzUVdTELDeyJj0";
    yinfeng-asciinema-token = "00000000-0000-0000-0000-000000000000";
    yinfeng-id-ed25519 = " ";
    yinfeng-nix-access-tokens = " ";
  };
  rage = "${pkgs.rage}/bin/rage";
  buildSecret = name: content: ''
    "${rage}" --encrypt --recipient "${publicKey}" --output "$out/${name}.age" \
      "${pkgs.writeText "fake-secret-${name}-raw" content}"
  '';
  secretsDirForTest = pkgs.runCommand "secrets-for-test" { } ''
    mkdir -p "$out"
    ${lib.concatStrings (lib.mapAttrsToList buildSecret secretsForTest)}
  '';
in
{
  config = lib.mkIf (config.system.is-vm) {
    age.secrets-directory = secretsDirForTest;
    age.sshKeyPaths = lib.mkForce [
      ./test-key.txt
    ];
  };
}
