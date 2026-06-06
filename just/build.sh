#!/bin/sh
# just -- command runner (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=just
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag casey/just; }
build_tool() { cargo_install just just; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
