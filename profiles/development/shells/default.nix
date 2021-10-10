{ pkgs, ... }:

{
  programs.zsh.enable = true;
  programs.fish.enable = true;
  environment.systemPackages = (with pkgs.fishPlugins; [
    foreign-env
    done
    pkgs.libnotify # for done notification
  ]) ++ (with pkgs.nur.repos.linyinfeng.fishPlugins; [
    plugin-git
    plugin-bang-bang
    pisces
    replay-fish
  ]);

  programs.tprofile.enable = true;

  environment.global-persistence.user.directories = [
    ".local/share/fish"
  ];
}
