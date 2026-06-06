#!/bin/sh
# fd -- fast, user-friendly find (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=fd
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag sharkdp/fd; }
build_tool() { cargo_install fd-find fd; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
