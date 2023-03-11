{pkgs, ...}: {
  programs.fish.enable = true;
  environment.systemPackages =
    (with pkgs.fishPlugins; [
      foreign-env
      done
      autopair-fish
    ])
    ++ (with pkgs.nur.repos.linyinfeng.fishPlugins; [
      git
      bang-bang
      replay
    ])
    ++ (with pkgs; [
      libnotify # for done notification
      comma
    ]);

  programs.tprofile.enable = true;

  environment.global-persistence.user.directories = [
    ".local/share/fish"
  ];
}
