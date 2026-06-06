#!/bin/sh
# duf -- disk usage/free utility (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=duf
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag muesli/duf; }
build_tool() { go_install github.com/muesli/duf duf; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
