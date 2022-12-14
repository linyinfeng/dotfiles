{ self, channel, inputs, ... }: {
  nix.nixPath = [
    "nixpkgs=${channel.input}"
    "nixos-config=${self}/lib/compat/nixos"
    "home-manager=${inputs.home}"
  ];
}
