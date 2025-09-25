{ lib, ... }:
{
  options.testingFlags = {
    angrr = lib.mkEnableOption "angrr testing";
  };
  config = {
    testingFlags = {
      angrr = true;
    };
  };
}
