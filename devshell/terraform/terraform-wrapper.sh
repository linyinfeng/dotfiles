#!@shell@

set -e

source "@common@"
export PATH="@sops@/bin:$PATH"
export PATH="@terraform@/bin:$PATH"
export PATH="@zerotierone@/bin:$PATH"
export PATH="@minio-client@/bin:$PATH"
export PATH="@syncthing@/bin:$PATH"
export PATH="@jq@/bin:$PATH"
export PATH="@openssl@/bin:$PATH"
export PATH="@ruby@/bin:$PATH"
export PATH="@yq-go@/bin:$PATH"

encrypted="$PRJ_ROOT/secrets/terraform.tfstate"
plain="$PRJ_ROOT/terraform/terraform.tfstate"
message "decrypt terraform state to '$plain'..."
sops --input-type json --output-type json \
  --decrypt "$encrypted" >"$plain"

function cleanup {
  exit_code=$?

  set -e

  cd $PRJ_ROOT
  if [ -n "$(cat "$plain")" ]; then
    @encryptTo@ "$plain" "$encrypted" json "yq --prettyPrint"
  fi
  message "deleting terraform state '$plain'..."
  rm -f "$plain"* # remove plain and backup files

  echo "terraform exit code: $exit_code"
  exit $exit_code
}
trap cleanup EXIT

cd $PRJ_ROOT/terraform

set +e
terraform "$@"
