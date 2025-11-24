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
      ]);

    environment.global-persistence.user.directories = [ ".local/share/fish" ];
  }

  # bash
  { environment.global-persistence.user.files = [ ".bash_history" ]; }

  # nix-index
  {
    programs.command-not-found.enable = false;
    programs.nix-index =
      let
        enableIntegration = !(pkgs ? comma-with-db);
      in
      {
        enable = pkgs ? nix-index-with-db;
        package = pkgs.nix-index-with-db;
        enableBashIntegration = enableIntegration;
        enableZshIntegration = enableIntegration;
        enableFishIntegration = enableIntegration;
      };
  }

  # comma
  (lib.mkIf (pkgs ? comma-with-db) (
    let
      comma = pkgs.comma-with-db;
    in
    {
      programs.command-not-found.enable = false;
      environment.systemPackages = [ comma ];
      programs.bash.interactiveShellInit = ''
        function command_not_found_handle() {
          comma --ask "$@"
          return $?
        }
      '';
      programs.zsh.interactiveShellInit = ''
        function command_not_found_handler () {
          comma --ask "$@"
          return $?
        }
      '';
      programs.fish.interactiveShellInit = ''
        function fish_command_not_found
          "${lib.getExe comma}" --ask $argv
        end
      '';
    }
  ))
]
