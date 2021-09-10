# TODO: remove this after https://github.com/ryantm/agenix/issues/55 being resolved

{ lib, ... }:
{
  system.activationScripts.users.supportsDryActivation = lib.mkForce false;
}
