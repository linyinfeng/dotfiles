{
  pkgs,
  lib,
  ...
}:
lib.mkMerge [
  # fish
  {
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

    environment.global-persistence.user.directories = [
      ".local/share/fish"
    ];
  }

  # bash
  {
    environment.global-persistence.user.files = [
      ".bash_history"
    ];
  }
]
