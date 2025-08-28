{ ... }:

{
  programs.ssh.matchBlocks."*" = {
    controlMaster = "auto";
    controlPath = "~/.ssh/control-master-%r@%h:%p";
    controlPersist = "10m";
  };
}
