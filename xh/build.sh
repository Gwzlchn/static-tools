#!/bin/sh
# xh -- friendly HTTP client (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=xh
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag ducaale/xh; }
build_tool() { cargo_install xh xh; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
