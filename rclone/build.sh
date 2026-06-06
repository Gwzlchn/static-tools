#!/bin/sh
# rclone -- cloud storage sync (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=rclone
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag rclone/rclone; }
build_tool() { go_install github.com/rclone/rclone rclone; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
