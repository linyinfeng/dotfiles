{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # TODO wait for https://nixpk.gs/pr-tracker.html?pr=245351
    # wineWowPackages.staging
    wineWowPackages.stable
    winetricks
  ];

  environment.global-persistence.user.directories = [
    ".wine"
  ];
}
