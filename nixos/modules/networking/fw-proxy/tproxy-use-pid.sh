#!@shell@

set -e

cgroup_path="@cgroupPath@"

if [ "$#" != "1" ]; then
  cat <<EOF
Usage:
  $0 PID
EOF
  exit 1
fi

if [ ! -d "$cgroup_path" ]; then
  echo "cgroup not setup" >&2
  exit 1
fi

echo $1 >"$cgroup_path/cgroup.procs"
