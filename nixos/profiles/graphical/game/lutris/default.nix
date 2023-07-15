{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    lutris
  ];
  environment.global-persistence.user.directories = [
    ".local/share/lutris"
  ];
}
