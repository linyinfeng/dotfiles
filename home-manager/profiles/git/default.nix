{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    package =
      if config.home.graphical
      then pkgs.gitFull
      else pkgs.git;
    lfs.enable = true;

    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      pull.ff = "only";
      credential.helper = "libsecret";
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
  ];

  home.global-persistence.directories = [
    ".config/gh" # github-cli
  ];
}