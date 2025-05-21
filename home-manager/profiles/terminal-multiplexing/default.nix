{ ... }:
{
  programs.zellij = {
    enable = true;
    settings = {
      show_startup_tips = false;
      theme = "iceberg-dark";
      mouse_mode = true;
    };
  };
  programs.tmux = {
    enable = true;
    mouse = true;
  };
}
