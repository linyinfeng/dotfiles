#!@shell@

set -o errexit

set -o allexport
source "@environmentFile@"
set +o allexport
export RESTIC_PASSWORD_FILE="@passwordFile@"
export RESTIC_REPOSITORY="@repository@"

"@restic@/bin/restic" "$@"
