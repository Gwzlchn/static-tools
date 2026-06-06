#!/bin/sh
# jq -- JSON processor (C, static; oniguruma vendored via --with-oniguruma=builtin).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=jq
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag jqlang/jq | sed 's/^jq-//'; }
build_tool() {
  V="$RESOLVED_VERSION"
  apk add --no-cache build-base wget tar file ca-certificates >/dev/null
  cd /tmp
  retry 4 wget -q "https://github.com/jqlang/jq/releases/download/jq-${V}/jq-${V}.tar.gz"
  tar xf "jq-${V}.tar.gz"; cd "jq-${V}"
  ./configure --with-oniguruma=builtin --enable-static --disable-shared >/dev/null
  make -j"$(nproc)" LDFLAGS=-all-static >/dev/null
  echo '{"ok":true}' | ./jq -e .ok >/dev/null && echo "==> jq smoke ok"
  BIN="$PWD/jq"; BUILT_VERSION="$V"
}
run_recipe
