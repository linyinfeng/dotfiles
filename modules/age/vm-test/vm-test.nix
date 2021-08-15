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
    user-root-password = "$6$bj3/URz325$NMUMZHcKQzC0ZzTTSOqqn68MI2TwlZCuaC64TNUUVTyiF8Z/zqpgjt5m3cBXrBz2XJ5hOd9ZMUq3/VW9qT6K7.";
    user-yinfeng-password = "$6$B2VNSp7Q2hyKatgR$ozmqtZxDnKMJE8zdgIfwq8vYPkKuHmnWX7POvg.jKqPBtlzlbWpcY3lxxy7yTvjg9wG6C0MJUagnaPhDcdfZN.";
    yinfeng-asciinema-token = "00000000-0000-0000-0000-000000000000";
    yinfeng-id-ed25519 = " ";
    yinfeng-nix-access-tokens = " ";
  };
  rage = "${pkgs.rage}/bin/rage";
  buildSecret = name: content: ''
    echo -n "${content}" | "${rage}" --encrypt --recipient "${publicKey}" --output "$out/${name}.age" \
      "${pkgs.writeText "fake-secret-${name}-raw" content}"
  '';
  secretsDirForTest = pkgs.runCommandNoCC "secrets-for-test" { } ''
    mkdir -p "$out"
    ${lib.concatStrings (lib.mapAttrsToList buildSecret secretsForTest)}
  '';
in
{
  config = lib.mkIf (config.system.is-vm-test) {
    age.secrets-directory = secretsDirForTest;
    age.sshKeyPaths = lib.mkForce [
      ./test-key.txt
    ];
  };
}
