{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    man-pages # linux man pages
  ];
}
