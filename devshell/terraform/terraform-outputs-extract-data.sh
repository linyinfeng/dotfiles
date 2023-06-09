#!@shell@
# shellcheck shell=bash

set -e

# shellcheck disable=SC1091
source "@common@"
export PATH="@yq-go@/bin:$PATH"
export PATH="@sops@/bin:$PATH"

pushd "$PRJ_ROOT/lib/data"

message "creating 'data.json'..."

sops exec-file "$PRJ_ROOT/secrets/terraform-outputs.yaml" \
  "yq eval --from-file template.yq {} --output-format json" \
  >"data.json"

popd
