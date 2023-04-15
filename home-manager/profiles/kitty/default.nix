{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "monospace";
      size = 11;
    };
    extraConfig = ''
      include ${./theme.conf}
    '';
  };
}
