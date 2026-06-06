#!/bin/sh
# dasel -- JSON/YAML/TOML/XML selector (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=dasel
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag TomWright/dasel; }
build_tool() { go_install github.com/tomwright/dasel/v3/cmd/dasel dasel; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
