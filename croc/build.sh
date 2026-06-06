#!/bin/sh
# croc -- secure peer-to-peer file transfer (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=croc
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag schollz/croc; }
build_tool() { go_install github.com/schollz/croc/v10 croc; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
