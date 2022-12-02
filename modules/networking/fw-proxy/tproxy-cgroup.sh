#!@shell@

nft_table="@nftTable@"

set -e

action="$1"
level="$2"
path="$3"

function usage {
  cat <<EOF
Usage:
  $0 list   LEVEL
  $0 add    LEVEL PATH
  $0 delete LEVEL PATH
EOF
  exit 0
}

case "$action" in

  list)
    if [ $# != 2 ]; then usage; fi
    nft list set inet "$nft_table" level"$level"-cgroups
    ;;

  add|delete)
    if [ $# != 3 ]; then usage; fi
    nft "$action" element inet "$nft_table" level"$level"-cgroups \
        "{ \"$path\" }"
    ;;

  *)
    usage
    ;;
esac
