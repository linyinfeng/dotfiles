{ pkgs, lib, ... }:
let
  fileLineColumnHandler = pkgs.writeShellScriptBin "file-line-column-handler" ''
    set -e
    [[ "$1" =~ ^file-line-column://([^:]+):(.*)$ ]]
    file="''${BASH_REMATCH[1]}"
    line_column="''${BASH_REMATCH[2]}"
    emacsclient --no-wait +"$line_column" "$file"
  '';
in
lib.mkMerge [
  {
    programs.git = {
      enable = true;
      package = pkgs.gitFull;
      lfs.enable = true;

      settings = {
        init.defaultBranch = "main";
        pull.rebase = false;
        pull.ff = "only";
        credential = {
          helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
          credentialStore = "secretservice";
          # git-credential-manager specified configurations
          # https://github.com/git-ecosystem/git-credential-manager/blob/main/docs/autodetect.md
          provider = "auto";
          "https://github.com".provider = "github";
          "https://gitlab.com".provider = "gitlab";
          "https://git.nju.edu.cn".provider = "gitlab";
        };
        commit.gpgSign = true;

        # fish git status
        bash.showInformativeStatus = true;
      };
    };

    home.packages = with pkgs; [
      github-cli
      git-credential-manager
    ];

    home.global-persistence.directories = [
      ".config/gh" # github-cli
    ];
  }

  # jujutsu
  {
    programs.jujutsu.enable = true;
  }

  # delta
  {
    programs.delta = {
      enable = true;
      enableGitIntegration = true;
      enableJujutsuIntegration = true;
      options = {
        navigate = true;
        light = true;
        line-numbers = true;
        hyperlinks = true;
        hyperlinks-file-link-format = "file-line-column://{path}:{line}";
      };
    };
    programs.git.settings = {
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
    home.packages = [ fileLineColumnHandler ];
    xdg.desktopEntries = {
      file-line-column-handler = {
        name = "file-line-column-handler";
        genericName = "File line URI handler";
        exec = "${fileLineColumnHandler}/bin/file-line-column-handler %U";
        icon = "emacs";
        type = "Application";
        categories = [ "Utility" ];
        startupNotify = false;
        mimeType = [ "x-scheme-handler/file-line-column" ];
      };
    };
    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/file-line-column" = [ "file-line-column-handler.desktop" ];
    };
  }
]
