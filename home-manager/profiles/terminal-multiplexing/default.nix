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
    terminal = "tmux-256color";
    extraConfig = ''
      set -s extended-keys on
      set -as terminal-features 'alacritty*:extkeys,xterm*:extkeys'
      set -g allow-passthrough on
    '';
  };
}
