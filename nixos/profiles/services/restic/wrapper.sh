#!@shell@
# shellcheck shell=bash

set -o errexit

set -o allexport
# shellcheck disable=SC1091
source "@environmentFile@"
set +o allexport
export RESTIC_PASSWORD_FILE="@passwordFile@"
export RESTIC_REPOSITORY="@repository@"

"@restic@/bin/restic" "$@"
