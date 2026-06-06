#!/bin/sh
# bat -- cat with syntax highlighting (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=bat
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag sharkdp/bat; }
build_tool() { cargo_install bat bat; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
