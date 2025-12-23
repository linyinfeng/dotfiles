{ lib, ... }:
{
  options.testingFlags = {
    angrr = lib.mkEnableOption "angrr testing";
    angrrNixpkgs = lib.mkEnableOption "angrr nixpkgs testing";
  };
  config = {
    testingFlags = {
      angrr = true;
      angrrNixpkgs = false;
    };
  };
}
