# TODO https://github.com/NixOS/nixpkgs/pull/187562
final: prev: {
  gnupg = prev.gnupg.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      # Fix regression when using YubiKey devices as smart cards.
      # See https://dev.gnupg.org/T6070 for details.
      # Committed upstream, remove this patch when updating to the next release.
      (final.fetchpatch {
        url = "https://dev.gnupg.org/rGf34b9147eb3070bce80d53febaa564164cd6c977?diff=1";
        sha256 = "sha256-J/PLSz8yiEgtGv+r3BTGTHrikV70AbbHQPo9xbjaHFE=";
      })
    ];
  });
}
