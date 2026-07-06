{ lib, ... }:
{
  options.programs.desktop-files = {
    favorites = lib.mkOption {
      type = with lib.types; listOf str;
      default = [ ];
      description = "Favorite desktop files";
    };
  };
}
