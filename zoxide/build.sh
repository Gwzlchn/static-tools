#!/bin/sh
# zoxide -- smarter cd (Rust, static via musl + crt-static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=zoxide
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag ajeetdsouza/zoxide; }
build_tool() { cargo_install zoxide zoxide; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
