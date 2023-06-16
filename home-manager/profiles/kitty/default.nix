{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "IosevkaYinfeng Nerd Font";
      size = 11;
    };
    extraConfig = ''
      include ${./theme.conf}
    '';
  };
}
