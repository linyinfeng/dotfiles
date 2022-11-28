final: prev: {
  fwupd = prev.fwupd.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./fwupd-lockdown-unknown-as-invalid.patch
    ];
  });
}
