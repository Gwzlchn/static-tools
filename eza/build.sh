#!/bin/sh
# eza -- modern ls (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=eza
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag eza-community/eza; }
build_tool() { cargo_install eza eza; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
