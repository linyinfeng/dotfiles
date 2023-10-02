#!@shell@
# shellcheck shell=bash

nft_table="@nftTable@"

set -e

action="$1"
path="$2"

function usage {
  cat <<EOF
Usage:
  $0 list
  $0 add    PATH
  $0 delete PATH
EOF
  exit 0
}

case "$action" in

list)
  if [ $# != 1 ]; then usage; fi
  nft list set inet "$nft_table" cgroups
  ;;

add | delete)
  if [ $# != 2 ]; then usage; fi
  nft "$action" element inet "$nft_table" cgroups "{ \"$path\" }"
  ;;

*)
  usage
  ;;
esac
