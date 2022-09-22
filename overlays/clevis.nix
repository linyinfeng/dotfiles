# TODO wait for https://nixpk.gs/pr-tracker.html?pr=191755
final: prev: {
  clevis = prev.clevis.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      (final.fetchurl {
        url = "https://github.com/latchset/clevis/commit/ee1dfedb9baca107e66a0fec76693c9d479dcfd9.patch";
        sha256 = "sha256-GeklrWWlAMALDLdnn6+0Bi0l+bXrIbYkgIyI94WEybM=";
      })
    ];
  });
}
