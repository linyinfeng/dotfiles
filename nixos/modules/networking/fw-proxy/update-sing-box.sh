#!@shell@
# shellcheck shell=bash

update="@updateSingBoxUrl@"

profile="$1"
shift

case "$profile" in

"main")
  $update "$(cat "@mainUrl@")" --profile-name "main" "$@"
  ;;

"alternative")
  $update "$(cat "@alternativeUrl@")" --profile-name "alternative" "$@"
  ;;

*)
  $update "$profile" "$@"
  ;;
esac
