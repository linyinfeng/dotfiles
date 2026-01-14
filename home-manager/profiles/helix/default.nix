{ lib, ... }:
{
  programs.helix = {
    enable = true;
    defaultEditor = true;
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
