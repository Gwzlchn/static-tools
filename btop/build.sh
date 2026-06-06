#!/bin/sh
# btop -- resource monitor (C++20, static via `make STATIC=true`).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=btop
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag aristocratos/btop; }
build_tool() {
  V="$RESOLVED_VERSION"
  apk add --no-cache build-base coreutils wget tar file ca-certificates >/dev/null
  cd /tmp
  retry 4 wget -q "https://github.com/aristocratos/btop/archive/refs/tags/v${V}.tar.gz" -O btop.tar.gz
  tar xf btop.tar.gz; cd "btop-${V}"
  make -j"$(nproc)" STATIC=true >/dev/null
  smoke ./bin/btop
  BIN="$PWD/bin/btop"; BUILT_VERSION="$V"
}
run_recipe
