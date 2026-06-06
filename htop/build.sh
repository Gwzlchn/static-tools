#!/bin/sh
# htop -- interactive process viewer (C, static; ncursesw).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=htop
ARCHES="x86_64"
DEFAULT_VERSION=latest
latest_version() { gh_latest_tag htop-dev/htop; }
build_tool() {
  V="$RESOLVED_VERSION"
  apk add --no-cache build-base ncurses-static ncurses-dev linux-headers pkgconf wget tar xz file ca-certificates >/dev/null
  cd /tmp
  retry 4 wget -q "https://github.com/htop-dev/htop/releases/download/${V}/htop-${V}.tar.xz"
  tar xf "htop-${V}.tar.xz"; cd "htop-${V}"
  ./configure --enable-static --enable-unicode >/dev/null
  make -j"$(nproc)" >/dev/null
  smoke ./htop
  BIN="$PWD/htop"; BUILT_VERSION="$V"
}
run_recipe
