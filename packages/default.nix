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
    maintain = callPackage ./maintain { };
    make-fake-secrets = callPackage ./make-fake-secrets { };
  }
)
