#!/bin/sh
# sops -- secrets management (Go, static via CGO_ENABLED=0).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=sops
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag getsops/sops; }
build_tool() { go_install github.com/getsops/sops/v3/cmd/sops sops; BUILT_VERSION="$RESOLVED_VERSION"; }
run_recipe
