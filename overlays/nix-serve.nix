# https://github.com/edolstra/nix-serve/issues/28
final: prev: {
  nix-serve = prev.nix-serve.override {
    nix = final.nix_2_3;
  };
}
