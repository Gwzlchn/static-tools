#!/bin/sh
# micro -- terminal editor (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=micro
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag zyedidia/micro; }
# micro's go.mod has replace directives -> go install refuses; clone + go build instead.
build_tool() { go_build zyedidia/micro ./cmd/micro micro; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
