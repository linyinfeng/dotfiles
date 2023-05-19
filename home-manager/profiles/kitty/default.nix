{...}: {
  programs.kitty = {
    enable = true;
    font = {
      name = "Iosevka Yinfeng Nerd Font";
      size = 11;
    };
    extraConfig = ''
      include ${./theme.conf}
    '';
  };
}
