{ lib, ... }:
{
  programs.helix = {
    enable = true;
    languages = { };
    settings = lib.mkMerge [
      { theme = "base16_default"; }
    ];
  };
  programs.alacritty.settings = {
    keyboard.bindings = [
      {
        key = "[";
        mods = "Control";
        chars = "\\u001b";
      }
    ];
  };
}
