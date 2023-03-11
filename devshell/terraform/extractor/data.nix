{
  writeShellScriptBin,
  yq-go,
  sops,
}:
writeShellScriptBin "terraform-outputs-extract-data" ''
  set -e

  export PATH=${yq-go}/bin:${sops}/bin:$PATH

  pushd $PRJ_ROOT/lib/data

  echo "creating 'data.json'..."
  sops exec-file $PRJ_ROOT/secrets/terraform-outputs.yaml \
    "yq eval --from-file \"template.yq\" {} --output-format json" \
    > "data.json"

  popd
''
