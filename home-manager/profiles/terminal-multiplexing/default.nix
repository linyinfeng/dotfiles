{ ... }:
{
  programs.zellij = {
    enable = true;
    settings = {
      default_mode = "locked";
      show_startup_tips = false;
      theme_dark = "iceberg-dark";
      theme_light = "iceberg-light";
      mouse_mode = true;
    };
  };
}
