{lib}: features: pkg:
pkg.overrideAttrs (old: {
  requiredSystemFeatures = lib.unique ((old.requiredSystemFeatures or []) ++ features);
})
