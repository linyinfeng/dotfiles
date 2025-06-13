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
        # keep-sorted start
        async-prompt
        autopair-fish
        done
        fish-you-should-use
        foreign-env
        forgit
        puffer
        # keep-sorted end
      ])
      ++ (with pkgs.nur.repos.linyinfeng.fishPlugins; [
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
