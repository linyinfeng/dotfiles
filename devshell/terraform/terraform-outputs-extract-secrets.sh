#!@shell@
# shellcheck shell=bash

set -e

# shellcheck disable=SC1091
source "@common@"
export PATH="@yq-go@/bin:$PATH"
export PATH="@sops@/bin:$PATH"
export PATH="@fd@/bin:$PATH"

pushd "$PRJ_ROOT/secrets"

mkdir -p terraform/hosts

tmp_dir=$(mktemp -t --directory encrypt.XXXXXXXXXX)
mkdir "$tmp_dir/hosts"
function cleanup {
  rm -r "$tmp_dir"
}
trap cleanup EXIT

function extract {
  name="$1"
  is_host="$2"

  if [ -z "$is_host" ]; then
    template_file="templates/$name.yq"

    plain_file="$tmp_dir/$name.plain.yaml"

    target_file="terraform/$name.yaml"
  else
    export hostname="$name"
    template_file="templates/hosts/$name.yq"
    host_template_file="templates/host.yq"

    plain_file="$tmp_dir/hosts/$name.plain.yaml"
    host_plain_file="$tmp_dir/$name.host.plain.yaml"

    target_file="terraform/hosts/$name.yaml"
  fi

  message "creating '$plain_file'..."
  sops exec-file terraform-outputs.yaml \
    "yq eval --from-file '$template_file' {}" \
    >"$plain_file"

  if [ -n "$host_template_file" ]; then
    message "creating '$host_plain_file'..."
    sops exec-file terraform-outputs.yaml \
      "yq eval --from-file '$host_template_file' {}" \
      >"$host_plain_file"

    message "merging '$host_plain_file' into '$plain_file'..."
    yq --inplace ". *= load(\"$host_plain_file\")" "$plain_file"
  fi

  @encryptTo@ "$plain_file" "$target_file" yaml "yq --prettyPrint"
}

extract common
extract infrastructure

mapfile -t host_names < <(fd '^.*\.yq$' templates/hosts --exec echo '{/.}')
for host_name in "${host_names[@]}"; do
  extract "$host_name" is_host
done

popd
