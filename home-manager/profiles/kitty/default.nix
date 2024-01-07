{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "monospace";
      size = 10;
    };
    settings = {
      cursor_shape = "block";
    };
    extraConfig = ''
      include ${./theme.conf}
    '';
  };
}
