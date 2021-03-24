#!@shell@

set -e

realpath="@coreutils@/bin/realpath"
df="@coreutils@/bin/df"
dirname="@coreutils@/bin/dirname"
mkdir="@coreutils@/bin/mkdir"
awk="@gawk@/bin/awk"
rsync="@rsync@/bin/rsync"
persist="@persist@"

NC='\033[0m'
function output {
    GREEN='\033[0;32m'
    printf "$GREEN-- "
    printf "$@"
    printf "$NC\n"
}

function failure {
    RED='\033[0;31m'
    printf "$RED-- "
    printf "$@"
    printf "$NC\n"
}

for file in $@
do
    source=$("$realpath" "$file")
    if [ ! -e "$source" ]; then
        failure "file is not a directory: '$source'"
        exit 1
    fi

    filesystem=$($df --portability "$source" | $awk 'NR==2{print$6}')
    if [ ! "$filesystem" = "/" ]; then
        output "file is not on filesystem '/': '$source'"
        exit 0
    fi

    target="$persist$source"

    if [ -d "$source" ]; then
        rsync_source="$source/"
    else
        rsync_source="$source"
    fi
    output "mkdir -p $($dirname "$target")"
    $mkdir -p $($dirname "$target")
    output "migrate '%s' to '%s'" "$source" "$target"
    $rsync --archive --recursive --progress --delete --compress \
      "$rsync_source" "$target"
    output "migration of '%s' finished" "$source"
done
