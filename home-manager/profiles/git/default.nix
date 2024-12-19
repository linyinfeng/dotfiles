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

      extraConfig = {
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

      aliases = {
        a = "add -p";
        co = "checkout";
        cob = "checkout -b";
        f = "fetch -p";
        c = "commit";
        p = "push";
        ba = "branch -a";
        bd = "branch -d";
        bD = "branch -D";
        d = "diff";
        dc = "diff --cached";
        ds = "diff --staged";
        r = "restore";
        rs = "restore --staged";
        st = "status -sb";

        # reset
        soft = "reset --soft";
        hard = "reset --hard";
        s1ft = "soft HEAD~1";
        h1rd = "hard HEAD~1";

        # logging
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        plog = "log --graph --pretty='format:%C(red)%d%C(reset) %C(yellow)%h%C(reset) %ar %C(green)%aN%C(reset) %s'";
        tlog = "log --stat --since='1 Day Ago' --graph --pretty=oneline --abbrev-commit --date=relative";
        rank = "shortlog -sn --no-merges";

        # delete merged branches
        bdm = "!git branch --merged | grep -v '*' | xargs -n 1 git branch -d";
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

  # delta
  {
    programs.git = {
      delta = {
        enable = true;
        options = {
          navigate = true;
          light = true;
          line-numbers = true;
          hyperlinks = true;
          hyperlinks-file-link-format = "file-line-column://{path}:{line}";
        };
      };
      extraConfig = {
        merge.conflictstyle = "diff3";
        diff.colorMoved = "default";
      };
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
