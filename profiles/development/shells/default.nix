{ pkgs, ... }:

{
  programs.fish.enable = true;
  environment.systemPackages = (with pkgs.fishPlugins; [
    foreign-env
    done
    pkgs.libnotify # for done notification
  ]) ++ (with pkgs.nur.repos.linyinfeng.fishPlugins; [
    git
    bang-bang
    replay
  ]);

  programs.tprofile.enable = true;

  environment.global-persistence.user.directories = [
    ".local/share/fish"
  ];
}
