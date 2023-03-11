{
  writeShellScriptBin,
  yq-go,
  sops,
  fd,
}:
writeShellScriptBin "terraform-outputs-extract-secrets" ''
  set -e

  export PATH=${yq-go}/bin:${sops}/bin:${fd}/bin:$PATH

  pushd $PRJ_ROOT/secrets

  mkdir -p terraform/hosts

  function extract {
    name="$1"
    host="$2"

    if [ -z "$host" ]; then
      template_file="templates/$name.yq"
      plain_file="terraform/$name.plain.yaml"
      target_file="terraform/$name.yaml"
    else
      export hostname="$name"
      template_file="templates/hosts/$name.yq"
      host_template_file="templates/host.yq"
      plain_file="terraform/hosts/$name.plain.yaml"
      host_plain_file="terraform/hosts/$name.host.plain.yaml"
      target_file="terraform/hosts/$name.yaml"
    fi

    echo "creating '$plain_file'..."
    sops exec-file terraform-outputs.yaml \
      "yq eval --from-file \"$template_file\" {}" \
      > "$plain_file"
    if [ -n "$host_template_file" ]; then
      echo "creating '$host_plain_file'..."
      sops exec-file terraform-outputs.yaml \
        "yq eval --from-file \"$host_template_file\" {}" \
        > "$host_plain_file"
      echo "merging '$host_plain_file' into '$plain_file'..."
      yq --inplace ". *= load(\"$host_plain_file\")" "$plain_file"
      echo "deleting '$host_plain_file'..."
      rm "$host_plain_file"
    fi
    echo "encrypting '$plain_file' to '$target_file'..."
    set +e
    EDITOR="cp \"$plain_file\"" sops "$target_file"
    encrypt_status="$?"
    set -e
    echo "deleting '$plain_file'..."
    rm "$plain_file"
    if [ "$encrypt_status" -ne 0 -a "$encrypt_status" -ne 200 ]; then
      echo "failed to encrypt, exiting"
      exit 1
    fi
  }

  extract common
  extract infrastructure

  host_names=($(fd '\.yq$' templates/hosts --exec echo '{/.}'))
  for host_name in "''${host_names[@]}"; do
    extract "$host_name" is_host
  done

  popd
''
