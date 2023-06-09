#!@shell@
# shellcheck shell=bash

update="@updateClashUrl@"

case "$1" in

"main")
  $update "$(cat "@mainUrl@")"
  ;;

"alternative")
  $update "$(cat "@alternativeUrl@")"
  ;;

"https://*" | "http://*")
  $update "$1"
  ;;
esac
