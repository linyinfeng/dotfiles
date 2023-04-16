{pkgs, ...}: {
  programs.sway = {
    enable = true;
    extraPackages = with pkgs; [
      swaylock-effects
      swayidle
    ];
  };
}
