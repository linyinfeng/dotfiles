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
      ++ (with pkgs.linyinfeng.fishPlugins; [
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
      environment.systemPackages = [ comma ];
      programs.bash.interactiveShellInit = ''
        export COMMAND_NOT_FOUND_SESSION_ID="''${COMMAND_NOT_FOUND_SESSION_ID:-$(cat /proc/sys/kernel/random/uuid)}"

        function command_not_found_handle() {
          if command -v comma >/dev/null 2>&1 && comma --print-packages "$1" >/dev/null 2>&1; then
            comma --ask "$@"
            return $?
          fi
          if [[ -n ''${COMMAND_NOT_FOUND_AGENT-} ]] && command -v "$COMMAND_NOT_FOUND_AGENT" >/dev/null 2>&1; then
            "$COMMAND_NOT_FOUND_AGENT" "$@"
            return $?
          fi
          echo "$1: command not found" >&2
          return 127
        }
      '';
      programs.zsh.interactiveShellInit = ''
        export COMMAND_NOT_FOUND_SESSION_ID="''${COMMAND_NOT_FOUND_SESSION_ID:-$(cat /proc/sys/kernel/random/uuid)}"

        function command_not_found_handler () {
          if command -v comma >/dev/null 2>&1 && comma --print-packages "$1" >/dev/null 2>&1; then
            comma --ask "$@"
            return $?
          fi
          if [[ -n ''${COMMAND_NOT_FOUND_AGENT-} ]] && command -v "$COMMAND_NOT_FOUND_AGENT" >/dev/null 2>&1; then
            "$COMMAND_NOT_FOUND_AGENT" "$@"
            return $?
          fi
          print -u2 "$1: command not found"
          return 127
        }
      '';
      programs.fish.interactiveShellInit = ''
        set -q COMMAND_NOT_FOUND_SESSION_ID
        and test -n "$COMMAND_NOT_FOUND_SESSION_ID"
        or set -gx COMMAND_NOT_FOUND_SESSION_ID (cat /proc/sys/kernel/random/uuid)

        # fish wires this function's stdout to stderr, so a command run from
        # here is not pipeable/redirectable (bash and zsh are).
        function fish_command_not_found
          if command -q comma; and comma --print-packages $argv[1] >/dev/null 2>&1
            comma --ask $argv
            return $status
          end
          if set -q COMMAND_NOT_FOUND_AGENT; and command -q "$COMMAND_NOT_FOUND_AGENT"
            $COMMAND_NOT_FOUND_AGENT $argv
            return $status
          end
          echo "$argv[1]: command not found" >&2
          return 127
        end
      '';
    }
  ))
]
