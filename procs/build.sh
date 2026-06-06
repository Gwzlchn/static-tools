#!/bin/sh
# procs -- modern ps replacement (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=procs
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag dalance/procs; }
build_tool() { cargo_install procs procs; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
