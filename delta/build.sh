#!/bin/sh
# delta -- syntax-highlighting git pager (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=delta
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag dandavison/delta; }
build_tool() { cargo_install git-delta delta; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
