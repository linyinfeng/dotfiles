{ writeShellScriptBin, yq-go, sops, fd }:

writeShellScriptBin "terraform-output-extractor" ''
  set -e

  pushd $PRJ_ROOT/secrets

  mkdir -p terraform

  template_names=($(${fd}/bin/fd '\.yq$' templates --exec echo '{/.}'))

  for name in "''${template_names[@]}"; do
    template_file="templates/$name.yq"
    target="terraform/$name.yaml"
    target_plain="terraform/$name.plain.yaml"
    echo "creating '$target_plain'..."
    if [ "$name" != "common" -a "$name" != "infrastructure" ]; then
      export hostname="$name"
    fi
    ${sops}/bin/sops exec-file terraform-outputs.yaml "${yq-go}/bin/yq eval --from-file \"$template_file\" {}" > "$target_plain"
    echo "encrypting '$target_plain' to '$target'..."
    ${sops}/bin/sops --encrypt "$target_plain" > "$target"
    echo "deleting '$target_plain'..."
    rm "$target_plain"
  done

  popd
''
