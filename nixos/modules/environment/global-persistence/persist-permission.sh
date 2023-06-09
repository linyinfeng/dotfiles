#!@shell@
# shellcheck shell=bash

fd="@fd@/bin/fd"
persist="@persist@"

uid=$(id --user)
gid=$(id --group)

$fd \
  --hidden \
  --type directory \
  --owner "!$uid:!$gid" \
  . "$persist$HOME" "$@"
