{ ... }:

{
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # log all commands executed
      "-a exit,always -S execve"
    ];
  };
}
