#!/bin/sh
# gdu -- fast disk usage analyzer (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=gdu
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag dundee/gdu; }
build_tool() { go_install github.com/dundee/gdu/v5/cmd/gdu gdu; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
