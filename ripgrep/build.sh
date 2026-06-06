#!/bin/sh
# ripgrep (rg) -- fast recursive search (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=ripgrep
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag BurntSushi/ripgrep; }
build_tool() { cargo_install ripgrep rg; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
