{ ... }:
{
  security.auditd.enable = true;
  security.audit = {
    enable = true;
    rules = [
      # log all commands executed by normal users
      "-a exit,always -F auid!=4294967295 -S execve"
    ];
  };
}
