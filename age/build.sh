#!/bin/sh
# age -- modern file encryption (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=age
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag FiloSottile/age; }
build_tool() { go_install filippo.io/age/cmd/age age; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
