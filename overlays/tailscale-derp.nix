final: prev: {
  tailscale-derp = final.tailscale.overrideAttrs (old: {
    subPackages = old.subPackages ++ [
      "cmd/derper"
    ];
  });
}
