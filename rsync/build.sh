#!/bin/sh
# rsync -- fully static, with zstd / lz4 / xxhash / openssl / acl / xattr support.
# zlib + popt are bundled (rsync --with-included-*); xxhash is built from source
# (Alpine ships no xxhash-static). musl + -static => one portable binary.
set -eu
. "$(dirname "$0")/../_lib.sh"

TOOL=rsync
ARCHES="x86_64 riscv64"
DEFAULT_VERSION=3.4.1

# Newest version from the authoritative samba release listing.
latest_version() {
  wget -qO- https://download.samba.org/pub/rsync/src/ \
    | sed -n 's/.*rsync-\([0-9][0-9.]*\)\.tar\.gz.*/\1/p' | sort -V | uniq | tail -n1
}

build_tool() {
  PREFIX=/opt/static
  XXHASH_VER=0.8.3
  JOBS=$(nproc)
  V="$RESOLVED_VERSION"

  apk add --no-cache build-base perl git wget tar xz file \
    zstd-static zstd-dev lz4-static lz4-dev \
    openssl-libs-static openssl-dev \
    acl-static acl-dev attr-static attr-dev >/dev/null

  mkdir -p "$PREFIX/lib" "$PREFIX/include" /build
  cd /build

  echo "==== xxHash ${XXHASH_VER} (static, from source) ===="
  retry 4 wget -q "https://github.com/Cyan4973/xxHash/archive/refs/tags/v${XXHASH_VER}.tar.gz" -O xxhash.tar.gz
  tar xf xxhash.tar.gz
  make -C "xxHash-${XXHASH_VER}" -j"$JOBS" libxxhash.a CFLAGS="-O2 -fPIC" >/dev/null
  cp "xxHash-${XXHASH_VER}/libxxhash.a" "$PREFIX/lib/"
  cp "xxHash-${XXHASH_VER}"/xxhash.h "$PREFIX/include/"
  cp "xxHash-${XXHASH_VER}"/xxh3.h "$PREFIX/include/" 2>/dev/null || true

  echo "==== rsync ${V} (static) ===="
  retry 4 wget -q "https://download.samba.org/pub/rsync/src/rsync-${V}.tar.gz"
  tar xf "rsync-${V}.tar.gz"
  cd "rsync-${V}"
  # -static forces .a selection; xxhash from $PREFIX, the rest from Alpine *-static.
  ./configure \
    --with-included-zlib --with-included-popt \
    --disable-md2man \
    CPPFLAGS="-I$PREFIX/include" \
    LDFLAGS="-static -L$PREFIX/lib" >/dev/null
  make -j"$JOBS" >/dev/null

  echo "==== smoke test ===="
  ./rsync --version | head -4
  # Assert the codecs/checksums we statically linked are actually compiled in
  # (acl/xattr too -- exercising them on overlayfs/QEMU is storage-driver dependent).
  for feat in xxh128 zstd lz4; do
    ./rsync --version | grep -q "$feat" || { echo "!! missing feature: $feat" >&2; exit 1; }
  done
  ./rsync --version | grep -qi openssl || { echo "!! missing feature: openssl" >&2; exit 1; }
  # Functional recursive sync (plain -a).
  mkdir -p /tmp/src/sub
  echo "hello-static-rsync" > /tmp/src/f.txt
  head -c 4096 /dev/urandom > /tmp/src/sub/rand.bin
  ./rsync -a /tmp/src/ /tmp/dst/
  grep -q hello-static-rsync /tmp/dst/f.txt && [ -f /tmp/dst/sub/rand.bin ] \
    && echo "==> smoke: recursive sync OK"
  ./rsync -a --checksum --compress --compress-choice=zstd /tmp/src/ /tmp/dst2/ \
    && echo "==> smoke: zstd + checksum OK"

  BUILT_VERSION="$V"
  BIN="$PWD/rsync"
}

run_recipe
