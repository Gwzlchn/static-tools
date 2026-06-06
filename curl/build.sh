#!/bin/sh
# curl -- HTTP client (C, static; OpenSSL + nghttp2 + zlib, all static).
set -eu
. "$(dirname "$0")/../_lib.sh"
TOOL=curl
ARCHES="x86_64"
DEFAULT_VERSION=latest
# curl tags look like "curl-8_11_0"; map to "8.11.0".
latest_version() { gh_latest_tag curl/curl | sed 's/^curl-//; s/_/./g'; }
build_tool() {
  V="$RESOLVED_VERSION"
  apk add --no-cache build-base openssl-libs-static openssl-dev zlib-static zlib-dev \
    nghttp2-static nghttp2-dev pkgconf wget tar xz file ca-certificates >/dev/null
  cd /tmp
  retry 4 wget -q "https://curl.se/download/curl-${V}.tar.gz"
  tar xf "curl-${V}.tar.gz"; cd "curl-${V}"
  ./configure --disable-shared --enable-static --with-openssl --with-nghttp2 \
    --disable-ldap --disable-ldaps --without-libpsl --without-brotli --without-zstd \
    --without-libidn2 PKG_CONFIG="pkg-config --static" >/dev/null
  # libtool needs -all-static (plain LDFLAGS=-static is ignored for the tool link).
  make -j"$(nproc)" curl_LDFLAGS=-all-static >/dev/null
  ./src/curl --version | grep -qi https && echo "==> curl https ok"
  BIN="$PWD/src/curl"; BUILT_VERSION="$V"
}
run_recipe
