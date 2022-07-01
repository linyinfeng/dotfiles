{ writeShellScriptBin, yq-go, sops, fd }:

writeShellScriptBin "terraform-output-extractor" ''
  set -e

  pushd $PRJ_ROOT/secrets

  mkdir -p terraform

  template_names=($(${fd}/bin/fd '\.yq$' templates --exec echo '{/.}'))

  for name in "''${template_names[@]}"; do
    template_file="templates/$name.yq"
    target="terraform/$name.yaml"
    echo "creating '$target'..."
    if [ "$name" != "common" -a "$name" != "infrastructure" ]; then
      export hostname="$name"
    fi
    ${sops}/bin/sops exec-file terraform-outputs.yaml "${yq-go}/bin/yq eval --from-file \"$template_file\" {}" > "$target"
    echo "encrypting '$target'..."
    ${sops}/bin/sops --encrypt --in-place "$target"
  done

  popd
''
