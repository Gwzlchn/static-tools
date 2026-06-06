#!/bin/sh
# dust -- intuitive du (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=dust
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag bootandy/dust; }
build_tool() { cargo_install du-dust dust; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
