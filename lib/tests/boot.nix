{
  name = "boot";

  machine = { ... }: { };

  testScript = ''
    machines[0].systemctl("is-system-running --wait")
  '';
}
