# shellcheck shell=bash

function message {
  green='\033[0;32m'
  no_color='\033[0m'
  echo -e "$green>$no_color $1" >&2
}

function messageVerbose {
  if [ "${VERBOSE:-}" = "1" ]; then
    message "$1"
  fi
}
