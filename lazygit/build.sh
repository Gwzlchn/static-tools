#!/bin/sh
# lazygit -- git TUI (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=lazygit
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag jesseduffield/lazygit; }
build_tool() { go_install github.com/jesseduffield/lazygit lazygit; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
