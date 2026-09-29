{ ... }:

{
  programs.ssh = {
    enable = true;
    # The legacy default block only restates OpenSSH's own defaults, so keep
    # the file down to the settings that actually differ.
    enableDefaultConfig = false;
    settings."*" = {
      ControlMaster = "auto";
      ControlPath = "~/.ssh/control-master-%r@%h:%p";
      ControlPersist = "10m";
    };
  };
}
