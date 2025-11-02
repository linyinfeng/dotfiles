{
  runCommand,
  jq,
  fd,
  make-fake-secrets,
}:
runCommand "fake-secrets"
  {
    nativeBuildInputs = [
      jq
      fd
      make-fake-secrets
    ];
    src = ../secrets;
  }
  ''
    cd "$src"
    fd '\.yaml$' --exec make-fake-secrets "{}" "$out/{}"
  ''
