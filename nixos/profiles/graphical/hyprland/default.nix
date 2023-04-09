{pkgs, ...}: {
  programs.hyprland.enable = true;
  security.pam.services.swaylock = {};
  environment.systemPackages = with pkgs; [
    light
  ];
  security.sudo.extraRules = [
    {
      groups = ["users"];
      commands = [
        {
          command = "/run/current-system/sw/bin/light";
          options = ["NOPASSWD"];
        }
      ];
    }
  ];
}
