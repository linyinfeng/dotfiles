{ ... }:

{
  programs.ssh = {
    controlMaster = "auto";
    controlPath = "~/.ssh/control-master-%r@%h:%p";
    controlPersist = "10m";
  };
}
