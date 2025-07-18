{
  lib,
  newScope,
}:
lib.makeScope newScope (
  self:
  let
    inherit (self) callPackage;
  in
  {
    fake-secrets = callPackage ./fake-secrets.nix { };
    make-fake-secrets = callPackage ./make-fake-secrets { };
  }
)
