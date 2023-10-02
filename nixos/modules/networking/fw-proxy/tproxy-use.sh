#!@shell@
# shellcheck shell=bash

cgroup_path="@cgroupPath@"

exec systemd-run --pipe --slice="$cgroup_path" "$@"
