{ pkgs, lib, ... }:
lib.mkMerge [
  # common
  {
    environment.shellAliases = {
      # sl = service log
      sl = "journalctl --unit";
    };
  }

  # fish
  {
    programs.fish.enable = true;
    environment.systemPackages =
      (with pkgs.fishPlugins; [
        foreign-env
        done
        autopair-fish
        async-prompt
      ])
      ++ (with pkgs.nur.repos.linyinfeng.fishPlugins; [
        git
        bang-bang
        replay
      ])
      ++ (with pkgs; [
        libnotify # for done notification
      ])
      ++ lib.optional (pkgs ? comma-with-db) pkgs.comma-with-db;

    environment.global-persistence.user.directories = [ ".local/share/fish" ];
  }

  # bash
  { environment.global-persistence.user.files = [ ".bash_history" ]; }
]
