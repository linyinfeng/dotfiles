#!@shell@

set -e

source "@common@"
export PATH="@terraform@/bin:$PATH"

cd $PRJ_ROOT/terraform

terraform init "$@"
