#!@shell@

nft_table="@nftTable@"
max_level="@maxCgroupLevel@"

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
  for level in $(seq 1 $max_level); do
    nft list set inet "$nft_table" cgroups-level"$level"
  done
  ;;

add | delete)
  if [ $# != 2 ]; then usage; fi
  IFS='/' read -ra path_arr <<<"$path"
  level="${#path_arr[@]}"
  nft "$action" element inet "$nft_table" cgroups-level"$level" \
    "{ \"$path\" }"
  ;;

*)
  usage
  ;;
esac
