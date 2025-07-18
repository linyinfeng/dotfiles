{
  runCommandNoCC,
  jq,
  fd,
  make-fake-secrets,
}:
runCommandNoCC "fake-secrets"
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
