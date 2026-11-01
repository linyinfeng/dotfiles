{
  lib,
  newScope,
  isDevSystem,
}:
lib.makeScope newScope (
  self:
  let
    inherit (self) callPackage;
  in
  {
    fish-direnv-completions = callPackage ./fish-direnv-completions { };
  }
  // lib.optionalAttrs isDevSystem {
    fake-secrets = callPackage ./fake-secrets.nix { };
    make-fake-secrets = callPackage ./make-fake-secrets { };
    maintain = callPackage ./maintain { };
  }
)
