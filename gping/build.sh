#!/bin/sh
# gping -- ping with a graph (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=gping
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag orf/gping; }
build_tool() { cargo_install gping gping; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
