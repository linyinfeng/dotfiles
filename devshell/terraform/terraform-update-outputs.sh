#!@shell@

set -e

source "@common@"
export PATH=$@yq-go@/bin:$PATH

pushd "$PRJ_ROOT/secrets"

tmp_dir=$(mktemp --directory /tmp/encrypt.XXXXXX)
function cleanup {
  rm -r "$tmp_dir"
}
trap cleanup EXIT

plain_output="$tmp_dir/terraform-outputs.plain.yaml"

@terraformWrapper@ output --json >"$plain_output"
@encryptTo@ "$plain_output" "terraform-outputs.yaml" yaml "yq --prettyPrint"
