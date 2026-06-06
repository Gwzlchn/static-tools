#!/bin/sh
# yq -- YAML/JSON/TOML processor (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=yq
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag mikefarah/yq; }
build_tool() { go_install github.com/mikefarah/yq/v4 yq; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
