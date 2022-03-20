final: prev: {
  __dontExport = true;

  # Fix impermanence
  utillinux = final.util-linux;
  # Fix nixpkgs gpg smartcards module
  runCommandNoCC = final.runCommand;
  # Fix nixpkgs waydroid module
  iproute = final.iproute2;
}
