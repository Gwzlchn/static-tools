#!/bin/sh
# sd -- intuitive find & replace (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=sd
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag chmln/sd; }
build_tool() { cargo_install sd sd; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
