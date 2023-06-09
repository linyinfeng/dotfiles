#!@shell@
# shellcheck shell=bash

set -e

# shellcheck disable=SC1091
source "@common@"
export PATH="@terraform@/bin:$PATH"

cd "$PRJ_ROOT/terraform"

terraform init "$@"
