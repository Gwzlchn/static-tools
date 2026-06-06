#!/bin/sh
# fzf -- fuzzy finder (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=fzf
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag junegunn/fzf; }
build_tool() { go_install github.com/junegunn/fzf fzf; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
