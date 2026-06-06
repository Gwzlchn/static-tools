#!/bin/sh
# gitui -- terminal git UI (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=gitui
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag extrawurst/gitui; }
# gitui's build.rs embeds the git commit, so build from a clone (not the crates.io tarball).
build_tool() { cargo_build_git extrawurst/gitui gitui; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
