{ pkgs, lib, budUtils, ... }: {
  bud.cmds = with pkgs; {
    get = {
      writer = budUtils.writeBashWithPaths [ nixVersions.selected git coreutils ];
      synopsis = "get [DEST]";
      help = "Copy the desired template to DEST";
      script = ./get.bash;
    };
  };
}
