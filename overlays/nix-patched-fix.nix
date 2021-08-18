# TODO: remove after upstream/main updated
final: prev: {
  nixUnstable = prev.nixUnstable.overrideAttrs (o: {
    patches =
      assert (builtins.length o.patches) == 1; [
        (prev.fetchpatch {
          name = "fix-follows.diff";
          url = "https://patch-diff.githubusercontent.com/raw/NixOS/nix/pull/4641.patch";
          sha256 = "sha256-0xNgbyWFmD3UIHPNFrgKiSejGJfuVj1OjqbS1ReLJRc=";
        })
      ];
  });
}
