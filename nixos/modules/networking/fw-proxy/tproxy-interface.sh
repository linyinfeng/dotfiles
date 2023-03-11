#!@shell@

nft_table="@nftTable@"

set -e

action="$1"
interface="$2"

function usage {
  cat <<EOF
Usage:
  $0 list
  $0 add    INTERFACE
  $0 delete INTERFACE
EOF
  exit 0
}

case "$action" in

list)
  if [ $# != 1 ]; then usage; fi
  nft list set inet "$nft_table" proxied-interfaces
  ;;

add | delete)
  if [ $# != 2 ]; then usage; fi
  nft "$action" element inet "$nft_table" proxied-interfaces "{ $interface }"
  ;;

*)
  usage
  ;;
esac
