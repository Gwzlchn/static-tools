#!/bin/sh
# hyperfine -- command-line benchmarking (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=hyperfine
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag sharkdp/hyperfine; }
build_tool() { cargo_install hyperfine hyperfine; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
